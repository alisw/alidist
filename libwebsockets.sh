package: libwebsockets
version: "%(tag_basename)s"
tag: "v2.4.2"
source: https://github.com/warmcat/libwebsockets
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
cmake $SOURCEDIR/                           \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_BUILD_TYPE=RELEASE            \
      -DLWS_WITH_STATIC=ON                  \
      -DLWS_WITH_SHARED=OFF                 \
      -DLWS_WITHOUT_TESTAPPS=ON
make ${JOBS+-j $JOBS} install
rm -rf $INSTALLROOT/share

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${OPENSSL_VERSION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}
# Our environment
setenv LIBWEBSOCKETS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(LIBWEBSOCKETS_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(LIBWEBSOCKETS_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(LIBWEBSOCKETS_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
