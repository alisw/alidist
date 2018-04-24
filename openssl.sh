package: OpenSSL
version: v0.9.8zf
tag: "v0.9.8_1.2.4"
source: https://github.com/alisw/alice-openssl.git
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  if [ `uname` = Darwin ]; then test -d `brew --prefix openssl || echo /dev/nope` || exit 1; fi; echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1
build_requires:
 - zlib
 - "GCC-Toolchain:(?!osx)"
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

OLD_OPENSSL=TRUE
if [ "$PKG_VERSION" == "*v1.0*" ]
then
    unset OLD_OPENSSL
    NEW_OPENSSL=TRUE
fi

pushd openssl
  ./config --openssldir="$INSTALLROOT" \
           ${OLD_OPENSSL:+--with-fipslibdir="$INSTALLROOT/fips/lib"}  \
           ${NEW_OPENSSL:+--with-fipslibdir="$INSTALLROOT/fips/lib/"} \
           ${NEW_OPENSSL:+--with-fipsdir="$INSTALLROOT/fips"} \
           fips \
           zlib \
           no-idea \
           no-mdc2 \
	   ${OLD_OPENSSL:+ no-ec no-ecdh no-ecdsa} \
           no-rc5 \
           no-asm \
           no-krb5 \
           shared \
           -fno-strict-aliasing \
           -L"${INSTALLROOT}/lib" \
           -Wa,--noexecstack \
           -DOPENSSL_USE_NEW_FUNCTIONS
  # Does not build in multicore!
  ${NEW_OPENSSL:+ make depend}
  make
  make install
popd

rm -rf $INSTALLROOT/pkgconfig \
       $INSTALLROOT/fips/pkgconfig \
       $INSTALLROOT/lib/*.a \
       $INSTALLROOT/fips/lib/*.a
