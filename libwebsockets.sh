package: libwebsockets
version: "%(tag_basename)s"
tag: "v2.4.2"
source: https://github.com/warmcat/libwebsockets
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - "OpenSSL:(?!osx)"
  - zlib
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*) [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl) ;;
esac
cmake $SOURCEDIR/                                                   \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      -DCMAKE_BUILD_TYPE=RELEASE                                    \
      -DLWS_WITH_STATIC=ON                                          \
      -DLWS_WITH_SHARED=OFF                                         \
      -DLWS_WITH_IPV6=ON                                            \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}             \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib}        \
      -DLWS_HAVE_OPENSSL_ECDH_H=OFF                                 \
      -DZLIB_ROOT=$ZLIB_ROOT                                        \
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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}
# Our environment
set LIBWEBSOCKETS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(LIBWEBSOCKETS_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(LIBWEBSOCKETS_ROOT)/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
