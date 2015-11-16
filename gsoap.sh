package: gSOAP
version: "%(tag_basename)s"
tag: v2.7.13
source: https://github.com/alisw/gsoap.git
build_requires:
 - autotools
 - OpenSSL
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
export CFLAGS="-fPIC -I$OPENSSL_ROOT/include -I$ZLIB_ROOT/include -L$OPENSSL_ROOT/lib -L$ZLIB_ROOT/lib"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
autoreconf -ivf
./configure --prefix=$INSTALLROOT \
            --enable-ssl \
            --with-openssl=$OPENSSL_ROOT
# Does not build in multicore!
make
make install
