package: xsimd
version: "8.1.0"
tag: 8.1.0
source: https://github.com/xtensor-stack/xsimd
requires:
  - Clang:(?!.*osx)
build_requires:
  - alibuild-recipe-tools
  - CMake
---

mkdir -p $INSTALLROOT
cd $BUILDDIR

cmake $SOURCEDIR                                                                                 \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Our environment
set XSIMD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$XSIMD_ROOT/lib
EoF
