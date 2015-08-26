package: HepMC
version: "%(short_hash)s"
source: https://github.com/alisw/hepmc
tag: master
---
#!/bin/bash -e

cmake  $SOURCEDIR \
       -Dmomentum=GEV \
       -Dlength=MM \
       -Dbuild_docs:BOOL=OFF \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install

# Modulefile
ModuleDir="${INSTALLROOT}/etc/Modules/modulefiles/${PKGNAME}"
mkdir -p "$ModuleDir"
cat > "${ModuleDir}/${PKGVERSION}-${PKGREVISION}" <<EoF
#%Module1.0#####################################################################
##
## ALICE - HepMC modulefile
##

proc ModulesHelp { } {
        global version
        puts stderr "This module is a module for HepMC."
}

set version $PKGVERSION-$PKGREVISION

module-whatis   "ALICE HepMC versions module"

## -- VERSION --
setenv          HEPMC_RELEASE  \$version
setenv          HEPMC_BASEDIR  \$::env(BASEDIR)/HepMC/\$::env(HEPMC_RELEASE)
prepend-path    LD_LIBRARY_PATH \$::env(HEPMC_BASEDIR)/lib
EoF
