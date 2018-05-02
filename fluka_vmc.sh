package: FLUKA_VMC
version: "%(tag_basename)s"
tag: "2011.2c-vmc2"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA_VMC.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
build_requires:
  - FLUKA
env:
  FLUVMC: "$FLUKA_VMC_ROOT"
  FLUPRO: "$FLUKA_VMC_ROOT/data"
---
#!/bin/bash -e

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ .
pushd source
  make ${JOBS:+-j$JOBS}
popd

# Installation
mkdir -p "$INSTALLROOT/lib"
cp -v lib/tgt_*/libfluka.* "$INSTALLROOT/lib"
cp -v README "$INSTALLROOT/"
rsync -av examples input "$INSTALLROOT"
rsync -av "$FLUKA_ROOT"/*.bin "$FLUKA_ROOT"/*.dat "$INSTALLROOT/data"

# Test load library
cat > loadFluka.C <<\EOF
#include <iostream>
#include <TSystem.h>
int loadFluka() {
  const char *libs[] = { "libVMC", "libPhysics", "libEG", "libfluka" };
  for (auto &lib : libs) {
    if (gSystem->Load(lib) < 0) {
      std::cout << "Cannot load library " << lib << std::endl;
      return 1;
    }
  };
  return 0;
}
EOF
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH
export ROOT_HIST=0
root -l -b -q -n loadFluka.C++

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
module load BASE/1.0 ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv FLUKA_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUVMC \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version/data
prepend-path LD_LIBRARY_PATH \$::env(FLUKA_VMC_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FLUKA_VMC_ROOT)/lib")
EoF
