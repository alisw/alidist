package: FLUKA
version: "%(tag_basename)s"
tag: "2011.2x"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA.git
requires:
  - "GCC-Toolchain:(?!osx)"
env:
  FLUPRO: "$FLUKA_ROOT"
  FLUFOR: "gfortran"
prepend_path:
  PATH: "$FLUKA_ROOT:$FLUKA_ROOT/flutil"
---
#!/bin/bash -e

if [[ $ARCHITECTURE == osx* || $ARCHITECTURE != *x86-64 ]]; then
  echo "FLUKA is precompiled for Linux x86_64 (you have $ARCHITECTURE), cannot continue."
  exit 1
fi

export FLUPRO=$PWD
export FLUFOR=gfortran

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ "$INSTALLROOT"
cd "$INSTALLROOT"
make ${JOBS:+-j$JOBS}

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
set FLUKA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
set FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUFOR gfortran
prepend-path PATH \$FLUKA_ROOT:\$::env(FLUKA_ROOT)/flutil
EoF
