package: G4HepEm
version: "%(tag_basename)s"
tag: 20261106-alice1
source: https://github.com/sawenzel/g4hepem
requires:
  - GEANT4
license: Apache-2.0
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR" -GNinja                    \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"   \
      -DCMAKE_INSTALL_LIBDIR=lib              \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}  \
      -DBUILD_SHARED_LIBS=ON                  \
      -DBUILD_TESTING=OFF                     \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EoF
# extra environment
set G4HEPEM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv G4HEPEM_ROOT \$G4HEPEM_ROOT
EoF
