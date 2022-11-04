package: grpc
version: "%(tag_basename)s"
tag:  v1.50.1
requires:
  - protobuf
  - c-ares
  - "OpenSSL:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
  - re2
build_requires:
  - CMake
  - abseil
source: https://github.com/grpc/grpc
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
    [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl@1.1)
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(brew --prefix protobuf)
  ;;
esac

cmake $SOURCEDIR                                    \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}           \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT               \
  -DgRPC_PROTOBUF_PACKAGE_TYPE="CONFIG"             \
  -DgRPC_BUILD_TESTS=OFF                            \
  -DBUILD_SHARED_LIBS=ON                            \
  -DgRPC_SSL_PROVIDER=package                       \
  -DgRPC_ZLIB_PROVIDER=package                      \
  -DgRPC_GFLAGS_PROVIDER=package                    \
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
module load BASE/1.0                                                          \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${C_ARES_REVISION:+c-ares/$C_ARES_VERSION-$C_ARES_REVISION}        \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION} \\
            ${RE2_REVISION:+re2/$RE2_VERSION-$RE2_REVISION} \\
            ${PROTOBUF_REVISION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}
# Our environment
set GRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$GRPC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GRPC_ROOT/lib
EoF
