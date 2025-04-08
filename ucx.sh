package: ucx
version: "%(tag_basename)s"
tag: v1.13.1-alice2
requires:
  - "GCC-Toolchain:(?!osx)"
  - rdma-core
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/ucx
---
#!/bin/bash -e

# Unified Communication X Library (linux only)

rsync -a --delete --exclude "**/.git" "${SOURCEDIR}"/ .
./autogen.sh
./contrib/configure-release-mt --prefix="${INSTALLROOT}"     \
                               --with-verbs                \
                               --with-rdmacm               \
                               --with-ib-hw-tm             \
                               --with-mlx5-dv              \
                               --with-rc                   \
                               --with-ud                   \
                               --with-dc                   \
                               --with-dm                   \
                               --with-avx                  \
                               --with-sse41                \
                               --with-sse42                \
                               --without-java              \
                               --without-go                \
                               --without-fuse3             \
                               --without-cuda              \
                               --without-rocm

make ${JOBS+-j$JOBS} || make -j1
make install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
