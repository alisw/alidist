package: VecGeom
version: "%(tag_basename)s"
tag: v2.1.0
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
            ${XERCESC_ROOT:+-DXercesC_ROOT=$XERCESC_ROOT}  \
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
            ${XERCESC_ROOT:+-DXercesC_ROOT=$XERCESC_ROOT}  \
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
            ${XERCESC_ROOT:+-DXercesC_ROOT=$XERCESC_ROOT}  \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ;;
esac

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
