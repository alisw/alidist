package: libwebsockets
version: "%(tag_basename)s"
tag: "v4.3.2"
source: https://github.com/warmcat/libwebsockets
requires:
  - libuv
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - "OpenSSL:(?!osx)"
  - ninja
  - alibuild-recipe-tools
# On Mac, Brew's libwebsockets loads Brew's Python, which confuses ROOT.
prefer_system: "(?!osx_)"
prefer_system_check: |
  #!/bin/bash -e
  cc -c -xc - -o /dev/null <<\EOF
  #if !__has_include(<lws_config.h>)
  #error "Cannot find libwebsocket"
  #endif
  EOF
  cc -c -xc - -o /dev/null <<\EOF
  #include <lws_config.h>
  #if LWS_LIBRARY_VERSION_NUMBER < 4000000
  #error "JAliEn-ROOT requires libwebsockets >= 4.0 but lesser version was detected"
  #endif
  EOF
---
#!/bin/bash -e
SONAME=so
case $ARCHITECTURE in
  osx*)
    SONAME=dylib
    : "${OPENSSL_ROOT:=$(brew --prefix openssl@3)}" ;;
esac

cmake $SOURCEDIR                                                    \
      -GNinja                                                       \
      -DCMAKE_C_FLAGS_RELEASE="-Wno-error"                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      -DCMAKE_BUILD_TYPE=RELEASE                                    \
      -DLWS_WITH_STATIC=ON                                          \
      -DLWS_WITH_SHARED=OFF                                         \
      -DLWS_WITH_IPV6=ON                                            \
      -DLWS_WITH_ZLIB=OFF                                           \
      ${OPENSSL_ROOT:+-DOPENSSL_EXECUTABLE=$OPENSSL_ROOT/bin/openssl} \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}             \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME}     \
      ${OPENSSL_ROOT:+-DLWS_OPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include}                                             \
      ${OPENSSL_ROOT:+-DLWS_OPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DLWS_WITH_LIBUV=ON                                           \
      ${LIBUV_REVISION:+-DLIBUV_INCLUDE_DIRS=$LIBUV_ROOT/include}   \
      ${LIBUV_REVISION:+-DLIBUV_LIBRARIES=$LIBUV_ROOT/lib/libuv.$SONAME} \
      -DLWS_HAVE_OPENSSL_ECDH_H=OFF                                 \
      -DLWS_WITHOUT_TESTAPPS=ON
cmake --build . --target install ${JOBS+-j $JOBS}
rm -rf $INSTALLROOT/share

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
