package: OpenSSL
version: v0.9.8zf
tag: "v0.9.8_1.2.4"
source: https://github.com/alisw/alice-openssl.git
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  if [ `uname` == Darwin ]; then test -d `brew --prefix openssl || echo /dev/nope` || exit 1; echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1; else exit 0; fi
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
