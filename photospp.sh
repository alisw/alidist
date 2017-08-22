package: PHOTOSPP
version: "%(tag_basename)s-ship%(defaults_upper)s"
tag: v3.61
source: https://github.com/PMunkes/PHOTOSPP
requires:
  - HepMC
  - ROOT
  - pythia
  - Tauolapp
---
#!/bin/sh

export  HEPMCLOCATION="$HEPMC_ROOT"

rsync -a $SOURCEDIR/* .

./configure --enable-debug --with-hepmc=$HEPMC_ROOT --with-pythia8=$PYTHIA_ROOT --with-tauola=$TAUOLAPP_ROOT --prefix=$INSTALLROOT CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"

mkdir lib

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION pythia/$PYTHIA_VERSION-$PYTHIA_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION  Tauolapp/$TAUOLAPP_VERSION-$TAUOLAPP_REVISION
# Our environment
setenv PHOTOSPP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(PHOTOSPP_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(PHOTOSPP_ROOT)/lib")
EoF
