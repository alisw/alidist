package: OpenSSL
version: v1.0.2o
tag: OpenSSL_1_0_2o
source: https://github.com/openssl/openssl
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  # Notice that we cannot use brew anymore, because they moved to 1.1.x.
  false
build_requires:
 - zlib:(?!osx)
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
case $ARCHITECTURE in 
  osx*) 
    EXTRA_DEPS="no-zlib enable-eec_nistp_64_gcc_128 no-comp"
    EXTRA_OPTS="-Wno-nonportable-include-path"
  ;;
  *) 
    EXTRA_DEPS=zlib
    EXTRA_OPTS="-Wa,--noexecstack" 
  :;
esac

export KERNEL_BITS=64
./config --prefix="$INSTALLROOT"                \
         --openssldir="$INSTALLROOT/etc/ssl"       \
         --libdir=lib                              \
         $TARGET                                   \
         $EXTRA_DEPS                               \
         no-idea                                   \
         no-mdc2                                   \
         no-rc5                                    \
         no-ec                                     \
         no-ecdh                                   \
         no-ecdsa                                  \
         no-asm                                    \
         no-krb5                                   \
         no-ssl2                                   \
         no-ssl3                                   \
         shared                                    \
         -fno-strict-aliasing                      \
         -L"$INSTALLROOT/lib"                      \
         $EXTRA_OPTS
make depend
make  # don't ever try to build in multicore
make install_sw

# Remove static libraries and pkgconfig
rm -rf $INSTALLROOT/lib/pkgconfig \
       $INSTALLROOT/lib/*.a

# Needed to make sure we can do the postprocessing on mac
find $INSTALLROOT -name "*.dylib" -exec chmod u+w {} \;

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
module load BASE/1.0 ${ZLIB_VERSION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv OPENSSL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(OPENSSL_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(OPENSSL_ROOT)/lib
EoF
