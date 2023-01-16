package: ObjCmp
version: "%(tag_basename)s"
tag: master
source: https://gitlab.cern.ch/swenzel/ObjectCmp.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
build_requires:
  - CMake
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT   \
          ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \
          -DROOT_DIR=${ROOT_ROOT}                      \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS}
make install

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
module load BASE/1.0 ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set OBJCMP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$OBJCMP_ROOT/lib
prepend-path PATH \$OBJCMP_ROOT/bin
EoF
