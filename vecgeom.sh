package: VecGeom
version: "%(tag_basename)s"
tag: v1.2.6
source: https://gitlab.cern.ch/VecGeom/VecGeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Vc"
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

cmake --build . -- ${JOBS+-j $JOBS} install

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
