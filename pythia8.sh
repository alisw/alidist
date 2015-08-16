package: pythia8
version: "v210"
source: https://github.com/alisw/pythia8
requires:
  - LHAPDF
  - HepMC
---
#!/bin/sh
cd $SOURCEDIR
./configure --prefix=$INSTALLROOT \
            --enable-shared \
            --with-hepmc2=${HEPMC_ROOT} \
            --with-lhapdf6=${LHAPDF_ROOT}

make ${JOBS+-j $JOBS}
make install
