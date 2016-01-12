package: MonALISA-gSOAP-client
version: "%(tag_basename)s"
tag: alice/v2.7.10
source: https://github.com/alisw/monalisa-gsoap-client.git
build_requires:
 - autotools
 - gSOAP
 - "GCC-Toolchain:(?!osx|slc5)"
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
export CFLAGS="-fPIC -I$GSOAP_ROOT/include -L$GSOAP_ROOT/lib"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
autoreconf -ivf
./configure --prefix=$INSTALLROOT
# Does not build in multicore!
make
make install
