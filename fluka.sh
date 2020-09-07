package: FLUKA
version: "%(tag_basename)s"
tag: "2011-3.0-vmc2"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
env:
  FLUPRO: "$FLUKA_ROOT/lib"
  FC: "gfortran"
prepend_path:
  PATH: "$FLUKA_ROOT/bin"
---
export FLUPRO=$PWD
export FC=gfortran

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ "$BUILDDIR"
make ${JOBS:+-j$JOBS}
mkdir -p $INSTALLROOT
cp -rf $BUILDDIR/bin $BUILDDIR/lib $BUILDDIR/include $BUILDDIR/data $INSTALLROOT/

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
cat >> $INSTALLROOT/etc/modulefiles/$PKGNAME <<EoF
# Our environment
set FLUKA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version/lib
prepend-path PATH \$FLUKA_ROOT/bin
EoF
