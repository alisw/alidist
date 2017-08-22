package: EvtGen
version: "%(tag_basename)s-ship%(defaults_upper)s"
tag: fairshipdev
source: https://github.com/PMunkes/evtgen
requires:
  - HepMC
  - pythia
  - Tauolapp
  - PHOTOSPP
---
#!/bin/sh

export  HEPMCLOCATION="$HEPMC_ROOT"

rsync -a $SOURCEDIR/* .

./configure --hepmcdir=$HEPMC_ROOT --pythiadir=$PYTHIA_ROOT --tauoladir=$TAUOLAPP_ROOT --photosdir=$PHOTOSPP_ROOT --prefix=$INSTALLROOT CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" 

make 
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
module load BASE/1.0 pythia/$PYTHIA_VERSION-$PYTHIA_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION  Tauolapp/$TAUOLAPP_VERSION-$TAUOLAPP_REVISION PHOTOSPP/$PHOTOSPP_VERSION-$PHOTOSPP_REVISION
# Our environment
setenv EVTGEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(EVTGEN_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(EVTGEN_ROOT)/lib")
EoF
