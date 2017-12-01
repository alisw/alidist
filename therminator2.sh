package: Therminator2
version: "%(tag_basename)s"
tag: "alice/v2.0.3"
source: https://github.com/alipwgmm/therminator
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
install -t ${INSTALLROOT}/bin therm2_events
install -t ${INSTALLROOT}/bin therm2_hbtfit
install -t ${INSTALLROOT}/bin therm2_femto
install -t ${INSTALLROOT}/bin therm2_parser 

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
module load BASE/1.0 ${HEPMC_VERSION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION} ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
setenv THERMINATOR2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(THERMINATOR2_ROOT)/bin
#prepend-path LD_LIBRARY_PATH \$::env(THERMINATOR2_ROOT)/lib
#$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(THERMINATOR2_ROOT)/lib")
EoF
