package: Upcgen
version: "%(tag_basename)s"
tag: upcgen-o2-21-11-24-2
source: https://github.com/alisw/upcgen
requires:
  - ROOT
  - HepMC3
  - pythia
build_requires:
  - CMake
  - GCC-Toolchain:(?!osx.*)
---
#!/bin/bash -e

cmake $SOURCEDIR                          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DBUILD_WITH_HEPMC=ON               \
      -DBUILD_WITH_OPENMP=ON              \
      -DBUILD_WITH_PYTHIA6=OFF            \
      -DBUILD_WITH_PYTHIA8=ON

cmake --build . -- ${JOBS:+-j$JOBS}
mkdir -p "$INSTALLROOT/bin"
cp "./upcgen" "$INSTALLROOT/bin/"
mkdir -p "$INSTALLROOT/lib"
cp "./libUpcgenlib.a" "$INSTALLROOT/lib/."
cp "./libUpcgenlib.so" "$INSTALLROOT/lib/."
cp -r "$SOURCEDIR/include" "$INSTALLROOT/."

#Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
