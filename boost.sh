package: boost
version: "%(tag_basename)s"
tag: v1.68.0
source: https://github.com/alisw/boost.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Python-modules:(?!osx)"
  - libpng
  - lzma
build_requires:
  - "bz2"
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"boost/version.hpp\"\n# if (BOOST_VERSION < 106800 || BOOST_VERSION > 106899)\n#error \"Cannot use system's boost: boost 1.68 required.\"\n#endif\nint main(){}" | c++ -I$(brew --prefix boost)/include -xc++ - -o /dev/null
prepend_path:
  ROOT_INCLUDE_PATH: "$BOOST_ROOT/include"
---
#!/bin/bash -e

BOOST_PYTHON=
BOOST_CXXFLAGS=
if [[ $ARCHITECTURE != osx* && $PYTHON_MODULES_VERSION ]]; then
  # Enable boost_python on platforms other than macOS
  BOOST_PYTHON=1
  if [[ $PYTHON_VERSION ]]; then
    # Our Python. We need to pass the appropriate flags to boost for the includes
    BOOST_CXXFLAGS="$(python3-config --includes)"
  else
    # Using system's Python. We want to make sure `python-config` is available in $PATH and points
    # to the Python 3 version. Note that a symlink will not work due to the automatic prefix
    # calculation of the python-config script. Our own Python does not require tricks
    if ! type python3-config &> /dev/null; then
      echo "FATAL: cannot find python3-config in your \$PATH. Cannot enable boost_python"
      exit 1
    fi
    mkdir fake_bin
    cat > fake_bin/python-config <<\EOF
#!/bin/bash
exec python3-config "$@"
EOF
    chmod +x fake_bin/python-config
    ln -nfs "$(which python3)" fake_bin/python
    ln -nfs "$(which pip3)" fake_bin/pip
    export PATH="$PWD/fake_bin:$PATH"
  fi
fi

BOOST_NO_PYTHON=
if [[ ! $BOOST_PYTHON ]]; then
  BOOST_NO_PYTHON=1
fi

if [[ $CXXSTD && $CXXSTD -ge 17 ]]; then
  # Use C++17: https://github.com/boostorg/system/issues/26#issuecomment-413631998
  CXXSTD=17
fi

TMPB2=$BUILDDIR/tmp-boost-build
case $ARCHITECTURE in
  osx*) TOOLSET=darwin ;;
  *) TOOLSET=gcc ;;
esac

rsync -a $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR/tools/build
# This is to work around an issue in boost < 1.70 where the include path misses
# the ABI suffix. E.g. ../include/python3 rather than ../include/python3m.
# This is causing havok on different combinations of Ubuntu / Anaconda
# installations.
case $ARCHITECTURE in
  osx*)  ;;
  *) export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:$(python3 -c 'import sysconfig; print(sysconfig.get_path("include"))')" ;;
esac
bash bootstrap.sh $TOOLSET
mkdir -p $TMPB2
./b2 install --prefix=$TMPB2
export PATH=$TMPB2/bin:$PATH
cd $BUILDDIR
b2 -q                                            \
   -d2                                           \
   ${JOBS+-j $JOBS}                              \
   --prefix=$INSTALLROOT                         \
   --build-dir=build-boost                       \
   --disable-icu                                 \
   --without-context                             \
   --without-coroutine                           \
   --without-graph                               \
   --without-graph_parallel                      \
   --without-locale                              \
   --without-math                                \
   --without-mpi                                 \
   ${BOOST_NO_PYTHON:+--without-python}          \
   --without-wave                                \
   --debug-configuration                         \
   toolset=$TOOLSET                              \
   link=shared                                   \
   threading=multi                               \
   variant=release                               \
   ${BOOST_CXXFLAGS:+cxxflags="$BOOST_CXXFLAGS"} \
   ${CXXSTD:+cxxstd=$CXXSTD}                     \
   install

# If boost_python is enabled, check if it was really compiled
[[ $BOOST_PYTHON ]] && ls -1 "$INSTALLROOT"/lib/*boost_python* > /dev/null

# We need to tell boost libraries linking other boost libraries to look for them
# inside the same directory as the main ones, on macOS (@loader_path).
if [[ $ARCHITECTURE == osx* ]]; then
  for LIB in $INSTALLROOT/lib/libboost*.dylib; do
    otool -L $LIB | grep -v $(basename $LIB) | { grep -oE 'libboost_[^ ]+' || true; } | \
      xargs -I{} install_name_tool -change {} @loader_path/{} "$LIB"
  done
fi

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
prepend-path ROOT_INCLUDE_PATH \$::env(BOOST_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BOOST_ROOT)/lib")
EoF
