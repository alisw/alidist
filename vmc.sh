package: VMC
version: "%(tag_basename)s"
tag: "v1-0-p3"
source: https://github.com/vmc-project/vmc
requires:
  - ROOT
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR"                             \
  -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
  -DCMAKE_INSTALL_LIBDIR=lib                   \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EoF
setenv VMC_ROOT \$PKG_ROOT
EoF
