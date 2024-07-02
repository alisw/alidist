package: JAliEn-ROOT
version: "%(tag_basename)s"
tag: "0.7.12"
source: https://gitlab.cern.ch/jalien/jalien-root.git
requires:
  - ROOT
  - xjalienfs
  - XRootD
  - libwebsockets
  - libuv
build_requires:
  - json-c
  - CMake
  - ninja
  - "GCC-Toolchain:(?!osx)"
  - zlib
  - Alice-GRID-Utils
  - alibuild-recipe-tools
append_path:
  ROOT_PLUGIN_PATH: "$JALIEN_ROOT_ROOT/etc/plugins"
  ROOT_INCLUDE_PATH: "$JALIEN_ROOT_ROOT/include"
---
#!/bin/bash -e
SONAME=so
case $ARCHITECTURE in
  osx*)
        SONAME=dylib
	[[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl@3)
	[[ ! $LIBWEBSOCKETS_ROOT ]] && LIBWEBSOCKETS_ROOT=$(brew --prefix libwebsockets)
  ;;
esac

# This is needed to support old version which did not have FindAliceGridUtils.cmake
ALIBUILD_CMAKE_BUILD_DIR=$SOURCEDIR
if [ ! -f "$JALIEN_ROOT_ROOT/cmake/modules/FindAliceGridUtils.cmake" ]; then
  ALIBUILD_CMAKE_BUILD_DIR="$BUILDDIR"
  rsync -a --exclude '**/.git' --delete "$SOURCEDIR/" "$BUILDDIR"
  rsync -a "$ALICE_GRID_UTILS_ROOT/include/" "$BUILDDIR/inc"
fi

cmake "$ALIBUILD_CMAKE_BUILD_DIR"                        \
      -G Ninja                                           \
      -DCMAKE_BUILD_TYPE=Debug                           \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"              \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=${CXXSTD}}          \
      -DROOTSYS="$ROOTSYS"                               \
      -DJSONC="$JSON_C_ROOT"                             \
      -DALICE_GRID_UTILS_ROOT="$ALICE_GRID_UTILS_ROOT"   \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
       ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
       ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DZLIB_ROOT="$ZLIB_ROOT"                           \
      -DXROOTD_ROOT_DIR="$XROOTD_ROOT"                   \
      -DLWS="$LIBWEBSOCKETS_ROOT"
cmake --build . -- ${JOBS:+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --cmake > "etc/modulefiles/$PKGNAME"
cat >> "etc/modulefiles/$PKGNAME" <<EoF
# Our environment
append-path ROOT_PLUGIN_PATH \$PKG_ROOT/etc/plugins
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
