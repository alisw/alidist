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
