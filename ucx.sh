package: ucx
version: "%(tag_basename)s"
tag: v1.13.1-alice1
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/ucx
---
#!/bin/bash -e

# Unified Communication X Library (linux only)
## NOTE: rdma-core and rdma-core-devel (v35+) packages must be installed for O2 FLP/EPN use

printf "#include <rdma/rdma_cma.h>" | cc -xc - -c -o /dev/null ||
( printf "rdma-core not found.\n * On RHEL-compatible systems you probably need: rdma-core-devel\n"; exit 1; )

rsync -a --delete --exclude "**/.git" ${SOURCEDIR}/ .
./autogen.sh
./contrib/configure-release-mt --prefix=${INSTALLROOT}     \
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
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
