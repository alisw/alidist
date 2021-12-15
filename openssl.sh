package: OpenSSL
version: v1.1.1m
tag: OpenSSL_1_1_1m
source: https://github.com/openssl/openssl
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  if [ `uname` = Darwin ]; then test -d `brew --prefix openssl@1.1 || echo /dev/nope` || exit 1; fi; echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl@1.1`/include -c -o /dev/null || exit 1; echo -e "#include <openssl/opensslv.h>\n#if OPENSSL_VERSION_NUMBER >= 0x10100000L\n#error \"System's GCC cannot be used: we need OpenSSL 1.0.x to build XrootD. We are going to compile our own version.\"\n#endif\nint main() { }" | cc -x c++ - -I`brew --prefix openssl@1.1`/include -c -o /dev/null || exit 1
build_requires:
 - zlib
 - "GCC-Toolchain:(?!osx)"
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
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > etc/modulefiles/$PKGNAME
cat << EOF >> etc/modulefiles/$PKGNAME
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
