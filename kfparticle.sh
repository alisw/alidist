package: KFParticle
version: "%(tag_basename)s"
tag: v1.1-alice8
source: https://github.com/alisw/KFParticle
requires:
  - ROOT
  - "GCC-Toolchain:(?!osx)"
  - Vc
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$KFPARTICLE_ROOT/include"
---
#!/bin/bash -e

cmake $SOURCEDIR                                        \
      -G Ninja                                          \
      ${VC_REVISION:+-DVc_INCLUDE_DIR=$VC_ROOT/include} \
      ${VC_VERSIOM:+-DVc_LIBRARIES=$VCROOT/lib/libVc.a} \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"             \
      -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"            \
      -DFIXTARGET=FALSE
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
$(alibuild-generate-module --bin --lib --root)
# Our environment
setenv KFPARTICLE_ROOT \$PKG_ROOT
EoF
