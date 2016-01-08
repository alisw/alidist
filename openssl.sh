package: OpenSSL
version: v0.9.8zf
prefer_system: osx
prefer_system_check: |
  echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null
build_requires:
 - zlib
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

case $ARCHITECTURE in 
  osx*)
  cat << \EOF
MacOSX builds require system installation of OpenSSL.

Please install it using homebrew:

    brew install openssl

or a similar system.
EOF
exit 1
  ;;
esac

# OpenSSL FIPS
FIPS_SHA1SUM='a79825c0c6743830ead3b6c3fd4c4e7fb09448a5'
curl -Lo openssl-fips.tgz \
         http://www.openssl.org/source/old/fips/openssl-fips-1.2.4.tar.gz
[ "$(sha1sum openssl-fips.tgz | awk '{print $1}')" == "$FIPS_SHA1SUM" ]
rm -rf openssl-fips
mkdir openssl-fips
pushd openssl-fips
  tar --strip-components=1 -xzf ../openssl-fips.tgz
  rm -f ../openssl-fips.tgz
  ./config --openssldir=$INSTALLROOT/fips \
           fipscanisterbuild \
           no-asm
  # Does not build in multicore!
  make
  make install
popd

# OpenSSL
OPENSSL_SHA1SUM='3f2f4ca864b13a237ae063cd34d01bbdbc8f108f'
HTTPCODE=$(curl -Lo openssl.tgz \
           http://www.openssl.org/source/old/0.9.x/openssl-0.9.8zf.tar.gz)
[ "$(sha1sum openssl.tgz | awk '{print $1}')" == "$OPENSSL_SHA1SUM" ]
rm -rf openssl
mkdir openssl
pushd openssl
  tar --strip-components=1 -xzf ../openssl.tgz
  rm -f ../openssl.tgz
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
