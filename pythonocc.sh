package: pythonOCC
version: "v7.9.3"
tag: 7.9.3
source: https://github.com/tpaviot/pythonocc-core.git
license: LGPLv2.1
requires:
  - OCCT
  - Python-modules
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
  - SWIG
  - RapidJSON
---
#!/bin/bash -e

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                   \
      -DPYTHONOCC_MESHDS_NUMPY=ON                                               \
      -DCMAKE_CXX_FLAGS="-isystem ${RAPIDJSON_ROOT}/include ${CMAKE_CXX_FLAGS}"

# Build and install
cmake --build . -- ${JOBS:+-j$JOBS} install

# find out python package installation path; PYTHONPATH needs the site-packages
# directory that CONTAINS the OCC package, not the package directory itself
OCC_PATH=$(dirname $(find ${INSTALLROOT} -name "OCC"))

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set PYTHONOCC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH ${OCC_PATH}
EOF
