package: ms_gsl
version: "3.1.0"
tag: v3.1.0
source: https://github.com/Microsoft/GSL.git
prepend_path:
  ROOT_INCLUDE_PATH: "$MS_GSL_ROOT/include"
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

# recipe for the C++ guidelines support library (Microsoft implementation)
# can be deleted once we are fully C++17 compliant
cmake $SOURCEDIR                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT    \
      -DGSL_TEST=OFF                         \
      ${CXXSTD:+-DGSL_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --root-env --extra > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
