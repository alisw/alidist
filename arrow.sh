package: arrow
version: 3fdeac74c80593ebde7a8eeb148cea9f6e0d1b38
source: https://github.com/apache/arrow
requires:
  - flatbuffers
  - boost
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
---
mkdir -p $INSTALLROOT
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FLATBUFFERS_ROOT ]] && FLATBUFFERS_ROOT=`brew --prefix flatbuffers`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

FLATBUFFERS_HOME=$FLATBUFFERS_ROOT            \
cmake $SOURCEDIR/cpp                          \
      -DARROW_BUILD_BENCHMARKS=OFF            \
      -DARROW_BUILD_TESTS=OFF                 \
      -DARROW_JEMALLOC=OFF                    \
      -DBOOST_ROOT=$BOOST_ROOT                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
      -DARROW_PYTHON=OFF

make ${JOBS:+-j $JOBS}
make install

#ModuleFil
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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv ARRAW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ARRAW_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ARRAW_ROOT)/lib")
prepend-path PATH \$::env(ARRAW_ROOT)/bin
EoF
