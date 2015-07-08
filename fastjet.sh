package: FastJet
version: "3.0.6_1.012"
---
#!/bin/bash -e

VerFJContrib="${PKGVERSION#*_}"
VerFJ="${PKGVERSION%%_*}"

UrlFJ="http://fastjet.fr/repo/fastjet-${VerFJ}.tar.gz"
UrlFJContrib="http://fastjet.hepforge.org/contrib/downloads/fjcontrib-${VerFJContrib}.tar.gz"

Boost='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0'
Cgal='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/cgal/v4.4'

curl -Lo fastjet.tar.gz "$UrlFJ"
curl -Lo fjcontrib.tar.gz "$UrlFJContrib"

tar xzf fastjet.tar.gz
tar xzf fjcontrib.tar.gz

export LD_LIBRARY_PATH="${Boost}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${Boost}/lib:${LIBRARY_PATH}"

# Build FastJet
cd $BUILDDIR/fastjet-$VerFJ
export CXXFLAGS="-Wl,--no-as-needed -lgmp -L${Boost}/lib -lboost_thread -lboost_system -L${Cgal}/lib -I${Boost}/include -I${Cgal}/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"
export CFLAGS="${CXXFLAGS}"
export CPATH="${Boost}/include:${Cgal}/include"
export C_INCLUDE_PATH="${Boost}/include:${Cgal}/include"
./configure \
  --enable-shared \
  --enable-cgal \
  --with-cgal="${Cgal}" \
  --prefix="$INSTALLROOT" \
  --enable-allcxxplugins
make -j$JOBS
make install -j$JOBS

# Build FastJet Contrib
cd $BUILDDIR/fjcontrib-$VerFJContrib
./configure \
  --fastjet-config=$INSTALLROOT/bin/fastjet-config \
  CXXFLAGS="$CXXFLAGS" \
  CFLAGS="$CFLAGS" \
  CPATH="$CPATH" \
  C_INCLUDE_PATH="$C_INCLUDE_PATH"
make -j$JOBS
make install
make fragile-shared -j$JOBS
make fragile-shared-install
