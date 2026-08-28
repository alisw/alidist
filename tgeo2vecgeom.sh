package: TGeo2VecGeom
version: "%(tag_basename)s"
tag: v0.1.2
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
      -DCMAKE_PREFIX_PATH="$VECGEOM_ROOT;$ROOT_ROOT"       \
      -DCMAKE_INSTALL_LIBDIR=lib                           \
      -DTGEO2VECGEOM_BUILD_TESTS=OFF                       \
      -GNinja

cmake --build . -- ${JOBS+-j $JOBS} install

# aliBuild only relocates references to our own INSTALLROOT, so a hardcoded dependency
# path breaks every consumer that gets us from the build cache. Skipped in devel mode.
if [ "${INSTALLROOT#"$WORK_DIR/$ARCHITECTURE/"}" = "$INSTALLROOT" ] &&
   grep -I -R -l -F "$WORK_DIR/$ARCHITECTURE/" "$INSTALLROOT"; then
  echo "ERROR: the files above hardcode a dependency path" >&2
  exit 1
fi

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --cmake > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set TGEO2VECGEOM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv TGEO2VECGEOM_ROOT \$TGEO2VECGEOM_ROOT
EOF
