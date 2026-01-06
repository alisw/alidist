package: HepMC
version: "%(tag_basename)s"
tag: HEPMC_02_06_10-alice1
source: https://gitlab.cern.ch/alisw/HepMC.git
build_requires:
  - CMake
  - GCC-Toolchain:(?!osx.*)
  - alibuild-recipe-tools
  - ninja
---
#!/bin/bash -e
cmake  $SOURCEDIR                           \
       -G Ninja                             \
       -Dmomentum=GEV                       \
       -Dlength=MM                          \
       -Dbuild_docs:BOOL=OFF                \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > "$MODULEFILE"

cat >> "$MODULEFILE" <<EoF
setenv HEPMC_ROOT \$PKG_ROOT
EoF
