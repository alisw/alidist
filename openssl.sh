package: OpenSSL
version: v0.9.8zf
tag: "v0.9.8_1.2.4"
source: https://github.com/alisw/alice-openssl.git
prefer_system: (?!slc5|slc6|osx)
prefer_system_check: |
 echo '#include <openssl/bio.h>' | c++ -x c++ - -c -o /dev/null || exit 1
build_requires:
 - zlib
 - "GCC-Toolchain:(?!osx)"
system_requirement_missing: |
 Please make sure you install openssl using Homebrew (brew install openssl)
system_requirement: "osx.*"
system_requirement_check: |
 echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null
---
#!/bin/bash -e

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

pushd openssl-fips
  ./config --openssldir=$INSTALLROOT/fips \
           fipscanisterbuild \
           no-asm
  # Does not build in multicore!
  make
  make install
popd

pushd openssl
  ./config --openssldir="$INSTALLROOT" \
           --with-fipslibdir="$INSTALLROOT/fips/lib" \
           fips \
           zlib \
           no-idea \
           no-mdc2 \
           no-rc5 \
           no-ec \
           no-ecdh \
           no-ecdsa \
           no-asm \
           no-krb5 \
           shared \
           -fno-strict-aliasing \
           -L"${INSTALLROOT}/lib" \
           -Wa,--noexecstack \
           -DOPENSSL_USE_NEW_FUNCTIONS
  # Does not build in multicore!
  make
  make install
popd

rm -rf $INSTALLROOT/pkgconfig \
       $INSTALLROOT/fips/pkgconfig \
       $INSTALLROOT/lib/*.a \
       $INSTALLROOT/fips/lib/*.a
