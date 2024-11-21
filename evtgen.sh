package: EVTGEN
version: "%(tag_basename)s"
tag: "R02-02-00-alice2"
source: https://github.com/alisw/EVTGEN
requires:
  - HepMC
  - pythia
  - TAUOLA
  - PHOTOS
build_requires:
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
env:
  EVTGENDATA: "$EVTGEN_ROOT/share"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DEVTGEN_HEPMC3=OFF \
      -DHEPMC2_ROOT_DIR=$HEPMC_ROOT \
      -DEVTGEN_PYTHIA=ON \
      -DPYTHIA8_ROOT_DIR=$PYTHIA_ROOT \
      -DEVTGEN_PHOTOS=ON \
      -DPHOTOSPP_ROOT_DIR=$PHOTOS_ROOT \
      -DEVTGEN_TAUOLA=ON \
      -DTAUOLAPP_ROOT_DIR=$TAUOLA_ROOT
make ${JOBS:+-j$JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF

# Our environment
set EVTGEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv EVTGEN_ROOT \$EVTGEN_ROOT
prepend-path PATH \$EVTGEN_ROOT/bin
prepend-path LD_LIBRARY_PATH \$EVTGEN_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
