package: VecGeom
version: "%(tag_basename)s"
tag: v2.1.1
source: https://gitlab.cern.ch/VecGeom/VecGeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Vc"
  - xercesc
license: Apache-2.0
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/bash -e
# Only the SIMD backend really differs per architecture: Vc with SSE4.2 on
# x86-64, plain scalar on arm64, where Vc has no backend.
case $ARCHITECTURE in
  osx_arm64) VECGEOM_BACKEND=Scalar; APPLE_SILICON_PROCESSOR=arm64 ;;
  *_aarch64) VECGEOM_BACKEND=Scalar ;;
  *)         VECGEOM_BACKEND=Vc; VECGEOM_VECTOR=sse4.2 ;;
esac

cmake "$SOURCEDIR" -GNinja                                                                 \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                \
      -DCMAKE_INSTALL_LIBDIR=lib                                                           \
      -DVECGEOM_BACKEND="$VECGEOM_BACKEND"                                                 \
      -DVECGEOM_BUILTIN_VECCORE=ON                                                         \
      -DBENCHMARK=OFF                                                                      \
      -DBUILD_TESTING=OFF                                                                  \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                   \
      ${VECGEOM_VECTOR:+-DVECGEOM_VECTOR=$VECGEOM_VECTOR}                                  \
      ${APPLE_SILICON_PROCESSOR:+-DCMAKE_APPLE_SILICON_PROCESSOR=$APPLE_SILICON_PROCESSOR} \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                              \
      ${XERCESC_ROOT:+-DXercesC_ROOT=$XERCESC_ROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

# VecCore 0.8.0, which VecGeom v1.2.6 pins and fetches via VECGEOM_BUILTIN_VECCORE,
# initialises fVal from the *previous* constructor's parameter name in a constructor
# nobody instantiates. WrappedScalar is the current instantiation there, so clang
# rejects it at definition time and o2codechecker fails on any TU reaching the header.
# Fixed upstream in VecCore 0.8.2; self-disabling once we pin a VecGeom that uses it.
VECCORE_SCALAR_WRAPPER="$INSTALLROOT/include/VecCore/Backend/ScalarWrapper.h"
if grep -q 'fVal(s->val_ptr)' "$VECCORE_SCALAR_WRAPPER" 2>/dev/null; then
  sed -i.bak 's|fVal(s->val_ptr)|fVal(s->fVal)|' "$VECCORE_SCALAR_WRAPPER"
  rm -f "$VECCORE_SCALAR_WRAPPER.bak"
fi

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
