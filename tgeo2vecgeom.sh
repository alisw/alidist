package: TGeo2VecGeom
version: "%(tag_basename)s"
tag: v0.1.0
source: https://gitlab.cern.ch/VecGeom/tgeo2vecgeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - VecGeom
  - ROOT
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/bash -e

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT      \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-RelWithDebInfo} \
      -DVecGeom_DIR=${VECGEOM_ROOT}/lib64/cmake/VecGeom    \
      -DTGEO2VECGEOM_BUILD_TESTS=OFF                       \
      -GNinja

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set TGEO2VECGEOM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv TGEO2VECGEOM_ROOT \$TGEO2VECGEOM_ROOT
EOF
