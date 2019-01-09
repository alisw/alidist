package: cpprestsdk
version: master
source: https://github.com/Microsoft/cpprestsdk
requires:
- boost
build_requires:
- CMake
tag: master
---
#!/bin/sh

case $ARCHITECTURE in
  osx*) BOOST_ROOT=$(brew --prefix boost) ;;
esac

cmake "$SOURCEDIR/Release"                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
      -DBUILD_TESTS=OFF                         \
      -DBUILD_SAMPLES=OFF                       \
      -DCMAKE_BUILD_TYPE=Debug                  \
      -DCMAKE_CXX_FLAGS=-Wno-error=conversion

make ${JOBS:+-j $JOBS}
make install

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
module load BASE/1.0
# Our environment
setenv CPPRESTSDK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(CPPRESTSDK_ROOT)/lib
EoF
