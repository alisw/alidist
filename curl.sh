package: curl
version: "7.70.0"
tag: curl-7_70_0
source: https://github.com/curl/curl.git
build_requires:
 - "OpenSSL:(?!osx)"
 - CMake
 - alibuild-recipe-tools
system_requirement: "slc8.*"
system_requirement_check:
   curl --version > /dev/null; if test $? = 127; then exit 1; else printf "#include <curl/curl.h>\nint main() {}\n" | cc -xc -lcurl - -o /dev/null || exit 2; fi; exit 0		
---
#!/bin/bash -e

if [[ $ARCHITECTURE = osx* ]]; then
  OPENSSL_ROOT=$(brew --prefix openssl)
else
  ${OPENSSL_ROOT:+env LDFLAGS=-Wl,-R$OPENSSL_ROOT/lib}
fi

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

./buildconf
./configure --prefix=$INSTALLROOT ${OPENSSL_ROOT:+--with-ssl=$OPENSSL_ROOT} --disable-static
make ${JOBS:+-j$JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set CURL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version before defining LD_LIBRARY_PATH
prepend-path PATH \$CURL_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CURL_ROOT/lib

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

