package: c-ares
version: "v1.15.0"
tag: cares-1_15_0
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
source: https://github.com/c-ares/c-ares
prefer_system: false
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

cmake $SOURCEDIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j$JOBS} install



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
set CARES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$CARES_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CARES_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$CARES_ROOT/lib")
EoF
