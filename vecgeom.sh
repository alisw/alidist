package: VecGeom
version: "%(tag_basename)s"
tag: 89a05d148cc708d4efc2e7b0eb6e2118d2610057
source: https://gitlab.cern.ch/VecGeom/VecGeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Vc"
  - ROOT
build_requires:
  - CMake
  - alibuild-recipe-tools
---

#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DROOT=ON  \
          -DBACKEND=Vc                                          \
          -DVECGEOM_VECTOR=sse4.2                               \
          -DBENCHMARK=ON                                        \
          ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}               \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --extra > "$MODULEDIR/$PKGNAME" <<\EoF
setenv VC_ROOT $PKG_ROOT
EoF
