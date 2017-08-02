package: boost
version: "%(tag_basename)s%(defaults_upper)s"
source: https://github.com/alisw/boost.git
tag: v1.59.0
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
 - "bz2"
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"boost/version.hpp\"\n# if (BOOST_VERSION < 105900)\n#error \"Cannot use system's boost. Boost > 1.59.00 required.\"\n#endif\nint main(){}" | cc -I$(brew --prefix boost)/include -xc++ - -o /dev/null && printf "int main(){}" | cc -L$(brew --prefix boost)/lib -xc++ - -o /dev/null -lboost_system -lboost_thread || printf "int main(){}" | cc -L$(brew --prefix boost)/lib -xc++ - -o /dev/null -lboost_system -lboost_thread-mt
---
#!/bin/bash -e

echo "Building ALICE boost. You can avoid that by installing at least boost 1.59."

# Detect whether we can enable boost-python (internal boost detection is broken)
BOOST_PYTHON=1
python -c 'import sys; sys.exit(1 if sys.version_info < (2, 7) else 0)'                   && \
  pip --help &> /dev/null                                                                 && \
  printf '#include \"pyconfig.h"' | gcc -c -I$(python-config --cflags) -xc -o /dev/null - || \
  unset BOOST_PYTHON
[[ $BOOST_PYTHON ]] || WITHOUT_PYTHON="--without-python"

TMPB2=$BUILDDIR/tmp-boost-build
case $ARCHITECTURE in
  osx*) TOOLSET=darwin ;;
  *) TOOLSET=gcc ;;
esac

rsync -a $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR/tools/build
bash bootstrap.sh $TOOLSET
mkdir -p $TMPB2
./b2 install --prefix=$TMPB2
export PATH=$TMPB2/bin:$PATH
cd $BUILDDIR
b2 -q                        \
   -d2                       \
   ${JOBS+-j $JOBS}          \
   --prefix=$INSTALLROOT     \
   --build-dir=build-boost   \
   --disable-icu             \
   --without-container       \
   --without-context         \
   --without-coroutine       \
   --without-graph           \
   --without-graph_parallel  \
   --without-locale          \
   --without-math            \
   --without-mpi             \
   $WITHOUT_PYTHON           \
   --without-wave            \
   toolset=$TOOLSET          \
   link=shared               \
   threading=multi           \
   variant=release           \
   $EXTRA_CXXFLAGS           \
   install
[[ $BOOST_PYTHON ]] && ls -1 "$INSTALLROOT"/lib/*boost_python* > /dev/null || true

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}
# Our environment
setenv BOOST_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(BOOST_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BOOST_ROOT)/lib")
EoF
