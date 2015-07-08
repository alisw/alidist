package: Rivet
version: "2.2.1"
requires:
  - GSL
  - YODA
  - FastJet
---
#!/bin/bash -e
Url="http://www.hepforge.org/archive/rivet/Rivet-${PKGVERSION}.tar.bz2"

# External dependencies. TODO: build them instead.
Boost="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0"
HepMC="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/HepMC/v2.06.09"
Cgal="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/cgal/v4.4"

curl -Lo rivet.tar.bz2 "$Url"
tar xjf rivet.tar.bz2
cd Rivet-$PKGVERSION
export LDFLAGS="-L$Cgal/lib -L$Boost/lib ${LDFLAGS}"
export LD_LIBRARY_PATH="${Cgal}/lib:${Boost}/lib:${LD_LIBRARY_PATH}"
./configure \
  --prefix="$INSTALLROOT" \
  --disable-doxygen \
  --with-yoda="$YODA_ROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-hepmc="$HepMC" \
  --with-fastjet="$FASTJET_ROOT" \
  --with-boost="$Boost"
make -j$JOBS
make install -j$JOBS
