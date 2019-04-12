package: grpc
version: "%(tag_basename)s"
tag:  v1.19.1
requires:
  - protobuf
  - c-ares
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
source: https://github.com/grpc/grpc
prefer_system: "(?!slc5)"
prefer_system_check: which grpc_cpp_plugin
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

pushd $SOURCEDIR
git checkout "$GIT_TAG"
git submodule update --init
popd

cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
  -DgRPC_PROTOBUF_PACKAGE_TYPE="CONFIG" \
  -DgRPC_BUILD_TESTS=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DgRPC_SSL_PROVIDER=package \
  -DgRPC_ZLIB_PROVIDER=package \
  -DgRPC_GFLAGS_PROVIDER=packet \
  -DgRPC_PROTOBUF_PROVIDER=package \
  -DgRPC_BENCHMARK_PROVIDER=packet \
  -DgRPC_CARES_PROVIDER=package \

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
module load BASE/1.0
# Our environment
set GRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$GRPC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GRPC_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$GRPC_ROOT/lib")
EoF
