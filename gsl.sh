package: GSL
version: "1.16"
---
#!/bin/bash -e
Url="ftp://ftp.gnu.org/gnu/gsl/gsl-${PKGVERSION}.tar.gz"
curl -o gsl.tar.gz "$Url"
tar xzf gsl.tar.gz
cd gsl-$PKGVERSION
./configure --prefix="$INSTALLROOT"
make -j$JOBS
make install -j$JOBS
