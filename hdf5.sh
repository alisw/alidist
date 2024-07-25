package: hdf5
version: "1.10.9"
tag: hdf5-1_10_9
source: https://github.com/HDFGroup/hdf5.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <hdf5.h>\n" | cc -xc - -c -o /dev/null
env:
    HDF5_DIR: "$HDF5_ROOT"
---
#!/bin/bash -e
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \
    -DHDF5_BUILD_CPP_LIB=ON

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
