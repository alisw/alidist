package: ndmspc
version: "%(tag_basename)s"
tag: "v1.0.0"
requires:
  - ROOT
  - JAliEn-ROOT
  - nlohmann_json
  - libwebsockets
  - curl
  - libuv
#  - arrow
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
  - "OpenSSL:(?!osx)"
source: https://gitlab.com/ndmspc/ndmspc.git
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
        [[ -n $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@3)
        [[ -n $LIBWEBSOCKETS_ROOT ]] || LIBWEBSOCKETS_ROOT=$(brew --prefix libwebsockets)
  ;;
esac

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"                \
      -G Ninja                                                          \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"}       \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                         \
      ${PROTOBUF_ROOT:+"-DPROTOBUF_ROOT=$PROTOBUF_ROOT"}                \
      ${LIBUV_ROOT:+"-DLIBUV_ROOT=$LIBUV_ROOT"}                         \
      ${LIBWEBSOCKETS_ROOT:+"-DLIBWEBSOCKETS_ROOT=$LIBWEBSOCKETS_ROOT"} \
      ${NLOHMANN_JSON_ROOT:+"-DNLOHMANN_JSON_ROOT=$NLOHMANN_JSON_ROOT"} \
      ${CURL_ROOT:+"-DCURL_ROOT=$CURL_ROOT"}                            \
      -DWITH_PARQUET=OFF                                                \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="$(readlink $SOURCEDIR || echo $SOURCEDIR)"
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# Modulefile
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/ndmspc
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
