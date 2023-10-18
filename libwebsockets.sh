package: libwebsockets
version: "%(tag_basename)s"
tag: "v3.0.1"
source: https://github.com/warmcat/libwebsockets
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - "OpenSSL:(?!osx)"
prefer_system: "osx"
prefer_system_check: |
  printf '#if !__has_include(<lws_config.h>)\n#error \"Cannot find libwebsocket\"\n#endif\n' | c++ -I$(brew --prefix libwebsockets)/include -c -xc++ -std=c++17 - -o /dev/null
  printf '#include <lws_config.h>\n#if LWS_LIBRARY_VERSION_NUMBER < 2004000 || LWS_LIBRARY_VERSION_NUMBER >= 3001000\n#error \"JAliEn-ROOT requires libwebsockets 3.0.x but other version was detected\"\n#endif\n' | c++ -c -x c++ -I$(brew --prefix libwebsockets)/include -std=c++17 - -o /dev/null || exit 1
---
#!/bin/bash -e
SONAME=so
case $ARCHITECTURE in
  osx*)
    SONAME=dylib
    : "${OPENSSL_ROOT:=$(brew --prefix openssl@3)}" ;;
esac

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ $BUILDDIR

# NOTE: drop this patch after libwebsockets is updated to 4.x
cat > xcode12.patch << EoF
--- private.h	2020-11-13 17:36:22.000000000 +0100
+++ private.h.patched	2020-11-13 17:54:05.000000000 +0100
@@ -298,8 +298,10 @@
  * but happily have something equivalent in the SO_NOSIGPIPE flag.
  */
 #ifdef __APPLE__
+#ifndef MSG_NOSIGNAL
 #define MSG_NOSIGNAL SO_NOSIGPIPE
 #endif
+#endif

 /*
  * Solaris 11.X only supports POSIX 2001, MSG_NOSIGNAL appears in
EoF

patch lib/core/private.h xcode12.patch

mkdir build
pushd build

cmake ..                                                            \
      -DCMAKE_C_FLAGS_RELEASE="-Wno-error"                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      -DCMAKE_BUILD_TYPE=RELEASE                                    \
      -DLWS_WITH_STATIC=ON                                          \
      -DLWS_WITH_SHARED=OFF                                         \
      -DLWS_WITH_IPV6=ON                                            \
      -DLWS_WITH_ZLIB=OFF                                           \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}             \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DLWS_HAVE_OPENSSL_ECDH_H=OFF                                 \
      -DLWS_WITHOUT_TESTAPPS=ON
make ${JOBS+-j $JOBS} install
rm -rf $INSTALLROOT/share

popd # build

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
                     ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}
# Our environment
set LIBWEBSOCKETS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LIBWEBSOCKETS_ROOT \$LIBWEBSOCKETS_ROOT
prepend-path PATH \$LIBWEBSOCKETS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LIBWEBSOCKETS_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
