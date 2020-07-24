package: FLUKA
version: "%(tag_basename)s"
tag: "2011-3.0-vmc2"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA.git
requires:
  - "GCC-Toolchain:(?!osx)"
env:
  FLUPRO: "$FLUKA_ROOT/lib"
  FC: "gfortran"
prepend_path:
  PATH: "$FLUKA_ROOT/bin"
---
#!/bin/bash -e

export FLUPRO=$PWD
export FC=gfortran

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
setenv FLUKA_ROOT \$FLUKA_ROOT
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version/lib
setenv FC gfortran
prepend-path PATH \$FLUKA_ROOT
prepend-path PATH \$FLUKA_ROOT/bin
EoF
