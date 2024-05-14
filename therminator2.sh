package: Therminator2
version: "%(tag_basename)s"
tag: "v2.0.3-alice3"
source: https://github.com/alisw/therminator
requires:
  - "GCC-Toolchain:(?!osx)"
  - HepMC
  - ROOT
---
#!/bin/bash -e

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ .
rsync -a $SOURCEDIR/fomodel ${INSTALLROOT}/
rsync -a $SOURCEDIR/macro ${INSTALLROOT}/
rsync -a $SOURCEDIR/share ${INSTALLROOT}/

make ${JOBS+-j $JOBS}

install -d ${INSTALLROOT}/bin
install therm2_events ${INSTALLROOT}/bin
install therm2_hbtfit ${INSTALLROOT}/bin
install therm2_femto ${INSTALLROOT}/bin
install therm2_parser ${INSTALLROOT}/bin 

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
module load BASE/1.0 ${HEPMC_REVISION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set THERMINATOR2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv THERMINATOR2_ROOT \$THERMINATOR2_ROOT
prepend-path PATH \$THERMINATOR2_ROOT/bin
#prepend-path LD_LIBRARY_PATH \$THERMINATOR2_ROOT/lib
EoF
