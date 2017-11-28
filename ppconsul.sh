package: Ppconsul
version: 0.0.1
tag: 8ade80d0528b563d4b58bc4f09815fc1e3d5be19
source: https://github.com/oliora/ppconsul
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
---
#!/bin/sh

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      -DBUILD_SHARED_LIBS=ON                                  \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}              \

make ${JOBS:+-j$JOBS}
#make install
mkdir $INSTALLROOT/lib
mkdir $INSTALLROOT/include
cp $BUILDROOT/$PKGNAME/output/libjson11.so $INSTALLROOT/lib/
cp $BUILDROOT/$PKGNAME/output/libppconsul.so $INSTALLROOT/lib/
cp -r $SOURCEDIR/include/* $INSTALLROOT/include/

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
module load BASE/1.0                                                          \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
