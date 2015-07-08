package: YODA
version: "1.3.1"
---
#!/bin/bash -e
Url="http://www.hepforge.org/archive/yoda/YODA-${PKGVERSION}.tar.bz2"
# TODO: will be a dependency
Boost="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0"
curl -Lo yoda.tar.bz2 "$Url"
tar xjf yoda.tar.bz2
cd YODA-$PKGVERSION
./configure --prefix="$INSTALLROOT" --with-boost="$Boost"
make -j$JOBS
make install -j$JOBS
