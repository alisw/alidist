package: OpenSSL
version: v1.1.1k
tag: OpenSSL_1_1_1k
source: https://github.com/openssl/openssl
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  if [ `uname` = Darwin ]; then test -d `brew --prefix openssl || echo /dev/nope` || exit 1; fi; echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1; echo -e "#include <openssl/opensslv.h>\n#if OPENSSL_VERSION_NUMBER >= 0x10100000L\n#error \"System's GCC cannot be used: we need OpenSSL 1.0.x to build XrootD. We are going to compile our own version.\"\n#endif\nint main() { }" | cc -x c++ - -I`brew --prefix openssl`/include -c -o /dev/null || exit 1
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
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${ZLIB_REVISION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set OPENSSL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv OPENSSL_ROOT \$OPENSSL_ROOT
prepend-path PATH \$OPENSSL_ROOT/bin
prepend-path LD_LIBRARY_PATH \$OPENSSL_ROOT/lib
EoF
