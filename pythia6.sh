# a pythia6 recipe based on the one from FairROOT
package: pythia6
version: "%(tag_basename)s"
tag: "428-alice4"
source: https://github.com/alisw/pythia6.git
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
  - ninja-fortran
  - alibuild-recipe-tools
---
#!/bin/sh

cmake ${SOURCEDIR}                           \
      -G Ninja                               \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}  \
      -DCMAKE_INSTALL_LIBDIR=lib
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv PYTHIA6_ROOT \$PKG_ROOT
prepend-path AGILE_GEN_PATH \$PYTHIA6_ROOT
EoF
