package: pytorch_cpuinfo
version: "alice1"
tag: b73ae6ce38d5dd0b7fe46dbe0a4b5f4bab91c7ea
source: https://github.com/pytorch/cpuinfo
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR"                        \
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}  \
  -DJSON_BuildTests=OFF                   \
  -DCPUINFO_BUILD_UNIT_TESTS=OFF          \
  -DCPUINFO_BUILD_MOCK_TESTS=OFF          \
  -DCPUINFO_BUILD_BENCHMARKS=OFF          \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"   \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
