package: c-ares
version: "1.18.1"
tag: cares-1_18_1
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
source: https://github.com/c-ares/c-ares
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

cmake $SOURCEDIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j$JOBS} install

case $ARCHITECTURE in
  osx*)
    # Add correct rpath to dylibs on Mac as long as there is no better way to
    # control rpath in the GRPC CMake
    # Add rpath to all libraries in lib and change their IDs to be absolute paths.
    find "$INSTALLROOT/lib" -name '*.dylib' -not -name '*ios*.dylib' \
         -exec install_name_tool -id '{}' '{}' \;
  ;;
esac

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
set C_ARES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$C_ARES_ROOT/bin
prepend-path LD_LIBRARY_PATH \$C_ARES_ROOT/lib
EoF
