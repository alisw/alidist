package: grpc
version: "%(tag_basename)s"
tag:  v1.19.1
requires:
  - protobuf
  - c-ares
  - OpenSSL
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
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
  -DgRPC_BENCHMARK_PROVIDER=packet                  \
  -DgRPC_BUILD_GRPC_CPP_PLUGIN=ON                   \
  ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR} \
  -DgRPC_CARES_PROVIDER=package

make ${JOBS:+-j$JOBS} install

if [[ $ARCHITECTURE == osx* ]]; then

  install_name_tool -change libgrpc_plugin_support.dylib @rpath/libgrpc_plugin_support.dylib $INSTALLROOT/bin/grpc_cpp_plugin

fi


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
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${C_ARES_VERSION:+c-ares/$C_ARES_VERSION-$C_ARES_REVISION}        \\
            ${PROTOBUF_VERSION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}
# Our environment
set GRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$GRPC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GRPC_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$GRPC_ROOT/lib")
EoF
