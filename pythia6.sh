# a pythia6 recipe based on the one from FairROOT
package: pythia6
version: "%(tag_basename)s"
tag: "428-alice2"
source: https://github.com/alisw/pythia6.git
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/sh

cmake ${SOURCEDIR}                           \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}  \
      -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root-env --extra > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path AGILE_GEN_PATH $PKG_ROOT
EoF
