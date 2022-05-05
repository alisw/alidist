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

case $ARCHITECTURE in
  os*) OPENSSL_ROOT=$(brew --prefix openssl@1.1) ;;
fi

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

./buildconf
./configure --prefix=$INSTALLROOT --disable-ldap ${OPENSSL_ROOT:+--with-ssl=$OPENSSL_ROOT} --disable-static
make ${JOBS:+-j$JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
