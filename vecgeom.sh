package: VecGeom
version: "%(tag_basename)s"
tag: v1.2.6
source: https://gitlab.cern.ch/VecGeom/VecGeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Vc"
license: Apache-2.0
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/bash -e
case $ARCHITECTURE in
    osx_arm64)
      cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
            -DCMAKE_APPLE_SILICON_PROCESSOR=arm64          \
            -DVECGEOM_BACKEND=Scalar                       \
            -GNinja                                        \
            -DBENCHMARK=OFF                                \
            -DBUILD_TESTING=OFF                            \
            -DVECGEOM_BUILTIN_VECCORE=ON                   \
            ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}        \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ;;
    *_aarch64)
      cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
            -DVECGEOM_BACKEND=Scalar                       \
            -GNinja                                        \
            -DBENCHMARK=OFF                                \
            -DBUILD_TESTING=OFF                            \
            -DVECGEOM_BUILTIN_VECCORE=ON                   \
            ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}        \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ;;
    *)
      cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
            -DVECGEOM_BACKEND=Vc                           \
            -DVECGEOM_VECTOR=sse4.2                        \
            -DBENCHMARK=OFF                                \
            -DBUILD_TESTING=OFF                            \
            -DVECGEOM_BUILTIN_VECCORE=ON                   \
            -GNinja                                        \
            ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}        \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ;;
esac

# VecGeom v1.2.6 fetches VecCore 0.8.0 during CMake configuration.
# Its WrappedScalar pointer constructor refers to a nonexistent member. GCC 15
# and clang diagnose this even without instantiation, so patch the staged header
# before compiling VecGeom, then also ensure the installed header is corrected.
fix_veccore_scalar_wrapper() {
  local header
  for header in "$@"; do
    if grep -q 'fVal(s->val_ptr)' "$header" 2>/dev/null; then
      sed -i.bak 's|fVal(s->val_ptr)|fVal(s->fVal)|' "$header"
      rm -f "$header.bak"
    fi
  done
}
fix_veccore_scalar_wrapper installExternals/VecCore-*/"${INSTALLROOT#/}"/include/VecCore/Backend/ScalarWrapper.h

cmake --build . -- ${JOBS+-j $JOBS} install

fix_veccore_scalar_wrapper "$INSTALLROOT/include/VecCore/Backend/ScalarWrapper.h"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set VECGEOM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VECGEOM_ROOT \$VECGEOM_ROOT
EOF
