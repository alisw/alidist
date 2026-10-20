package: Millepede-II
version: "%(tag_basename)s"
tag: "V05-01-06"
source: https://github.com/millepede-project/millepede-ii.git
requires:
  - Mille
  - zlib
  - openmp
  - OpenBLAS
  - "GCC-Toolchain:(?!osx)"
  - "gfortran-system:(osx.*)"
license: GPL-3.0
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --delete --exclude='**/.git' --delete-excluded "$SOURCEDIR/" ./

cmake "$SOURCEDIR"                              \
  -DCMAKE_BUILD_TYPE=Release                    \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"         \
  -DCMAKE_INSTALL_LIBDIR=lib                    \
  -DCMAKE_PREFIX_PATH="$OPENBLAS_ROOT"          \
  -DLAPACK_OPENBLAS=ON                          \
  -DSUPPORT_ROOT=OFF                            \
  -DSUPPORT_OPENMP=ON

cmake --build . -- ${JOBS+-j $JOBS}
cmake --install .

#ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin > "$MODULEFILE"
