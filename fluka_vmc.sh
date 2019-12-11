package: FLUKA_VMC
version: "%(tag_basename)s"
tag: "2011.2x-vmc1"
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
  ROOT_ETCDIR=$(root-config --etcdir)/vmc
  rsync -av "$ROOT_ETCDIR"/Makefile.* .
  for MK in Makefile.*; do
    grep -v libgfortranbegin -- "$MK" > "$MK".0
    mv "$MK".0 "$MK"
  done
  make ${JOBS:+-j$JOBS} SHELL='sh -x'
popd

# Installation
mkdir -p "$INSTALLROOT/lib"
cp -v lib/tgt_*/libfluka.* "$INSTALLROOT/lib"
cp -v README "$INSTALLROOT/"
for DIR in examples input; do
  [[ -d $DIR ]] || continue
  rsync -av $DIR "$INSTALLROOT"
done
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
module load BASE/1.0 ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set FLUKA_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUVMC \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version/data
prepend-path LD_LIBRARY_PATH \$FLUKA_VMC_ROOT/lib
EoF
