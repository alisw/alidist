package: vgm
version: "%(tag_basename)s"
tag: "v4-9"
source: https://github.com/vmc-project/vgm
requires:
  - ROOT
  - GEANT4
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
  -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -DCMAKE_INSTALL_LIBDIR="lib"                 \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

make ${JOBS+-j $JOBS} install

# Relocation of .cmake files
for CMAKE in $(find "$INSTALLROOT/lib" -name '*.cmake'); do
  sed -ideleteme -e "s!$ROOTSYS!\$ENV{ROOTSYS}!g; s!$G4INSTALL!\$ENV{G4INSTALL}!g" "$CMAKE"
done
find "$INSTALLROOT/lib" -name '*deleteme' -delete || true

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root-env > "$MODULEDIR/$PKGNAME"
