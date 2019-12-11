package: DPMJET
version: "%(tag_basename)s"
tag: "v3.0.5-alice4"
source: https://gitlab.cern.ch/ALICEPrivateExternals/DPMJET.git
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - "Xcode:(osx.*)"
---
#!/bin/bash -e

cmake  $SOURCEDIR                           \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS+-j $JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set DPMJET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(DPMJET_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(DPMJET_ROOT)/lib
EoF
