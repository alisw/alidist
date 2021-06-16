package: grpc
version: "%(tag_basename)s"
tag:  v1.34.0-alice1
requires:
  - protobuf
  - c-ares
  - "OpenSSL:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
  - re2
build_requires:
  - CMake
  - abseil
  - alibuild-recipe-tools
source: https://github.com/alisw/grpc
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

pushd $SOURCEDIR
git checkout "$GIT_TAG"
git submodule update --init
popd

case $ARCHITECTURE in
  osx*)
    [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl)
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(brew --prefix protobuf)
  ;;
esac

cmake $SOURCEDIR                                    \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT               \
  -DgRPC_PROTOBUF_PACKAGE_TYPE="CONFIG"             \
  -DgRPC_BUILD_TESTS=OFF                            \
  -DBUILD_SHARED_LIBS=ON                            \
  -DgRPC_SSL_PROVIDER=package                       \
  -DgRPC_ZLIB_PROVIDER=package                      \
  -DgRPC_GFLAGS_PROVIDER=packet                     \
  -DgRPC_PROTOBUF_PROVIDER=package                  \
  -DgRPC_ABSL_PROVIDER=package                      \
  -DgRPC_BENCHMARK_PROVIDER=packet                  \
  -DgRPC_BUILD_GRPC_CPP_PLUGIN=ON                   \
  -DgRPC_BUILD_CSHARP_EXT=OFF                       \
  -DgRPC_RE2_PROVIDER=package                       \
  ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR} \
  -DgRPC_CARES_PROVIDER=package

make ${JOBS:+-j$JOBS} install



MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEDIR/$PKGNAME"
