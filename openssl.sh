package: OpenSSL
version: v1.0.2o
tag: OpenSSL_1_0_2o
source: https://github.com/openssl/openssl
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  if [ `uname` = Darwin ]; then test -d `brew --prefix openssl || echo /dev/nope` || exit 1; fi; echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1; echo -e "#include <openssl/opensslv.h>\n#if OPENSSL_VERSION_NUMBER >= 0x10100000L\n#error \"System's GCC cannot be used: we need OpenSSL 1.0.x to build XrootD. We are going to compile our own version.\"\n#endif\nint main() { }" | cc -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1
build_requires:
 - zlib
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

./config --prefix="$INSTALLROOT"                   \
         --openssldir="$INSTALLROOT/etc/ssl"       \
         --libdir=lib                              \
         zlib                                      \
         no-idea                                   \
         no-mdc2                                   \
         no-rc5                                    \
         no-ec                                     \
         no-ecdh                                   \
         no-ecdsa                                  \
         no-asm                                    \
         no-krb5                                   \
         shared                                    \
         -fno-strict-aliasing                      \
         -L"$INSTALLROOT/lib"                      \
         -Wa,--noexecstack
make depend
make  # don't ever try to build in multicore
make install_sw # no not install man pages

# Remove static libraries and pkgconfig
rm -rf $INSTALLROOT/lib/pkgconfig \
       $INSTALLROOT/lib/*.a


# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env > "$MODULEDIR/$PKGNAME"
