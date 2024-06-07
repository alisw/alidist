package: curl
version: "7.70.0"
tag: curl-7_70_0
source: https://github.com/curl/curl.git
build_requires:
  - "OpenSSL:(?!osx)"
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

if [[ $ARCHITECTURE = osx* ]]; then
  OPENSSL_ROOT=$(brew --prefix openssl@3)
else
  ${OPENSSL_ROOT:+env LDFLAGS=-Wl,-R$OPENSSL_ROOT/lib}
fi
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

sed -i.deleteme 's/CPPFLAGS="$CPPFLAGS $SSL_CPPFLAGS"/CPPFLAGS="$SSL_CPPFLAGS $CPPFLAGS"/' configure.ac
sed -i.deleteme 's/LDFLAGS="$LDFLAGS $SSL_LDFLAGS"/LDFLAGS="$SSL_LDFLAGS $LDFLAGS"/' configure.ac

./buildconf
./configure --prefix=$INSTALLROOT --disable-ldap ${OPENSSL_ROOT:+--with-ssl=$OPENSSL_ROOT} --disable-static
make ${JOBS:+-j$JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
