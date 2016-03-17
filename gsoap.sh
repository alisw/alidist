package: gSOAP
version: "%(tag_basename)s"
tag: alice/v2.7.13
source: https://github.com/alisw/gsoap.git
build_requires:
 - autotools
 - "OpenSSL:(?!osx)"
 - "GCC-Toolchain:(?!osx|slc5)"
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./

# On mac we use openssl coming from homebrew.
case $ARCHITECTURE in 
  osx*)
    [ ! "X$OPENSSL_ROOT" = X ] || OPENSSL_ROOT=`brew --prefix openssl`
  ;;
esac
export CFLAGS="$CFLAGS ${OPENSSL_ROOT:+-I$OPENSSL_ROOT/include -L$OPENSSL_ROOT/lib} ${ZLIB_ROOT:+-I$ZLIB_ROOT/include -L$ZLIB_ROOT/lib}"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
autoreconf -ivf
./configure --prefix=$INSTALLROOT                          \
            --enable-ssl                                   \
            ${OPENSSL_ROOT:+--with-openssl=$OPENSSL_ROOT}
# Does not build in multicore!
make
make install
