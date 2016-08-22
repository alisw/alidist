package: DPMJET
version: "v3.0.5"
source: https://gitlab.cern.ch/ALICEPrivateExternals/DPMJET.git
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
---
#!/bin/bash -e

cmake  $SOURCEDIR                           \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

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
module load BASE/1.0
# Our environment
setenv MYGENERATOR_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(MYGENERATOR_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(MYGENERATOR_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MYGENERATOR_ROOT)/lib")
EoF
