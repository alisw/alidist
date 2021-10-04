package: O2Physics
version: "%(tag_basename)s"
tag: "nightly-20211004"
requires:
  - O2
  - ONNXRuntime
  - libjalienO2
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/O2Physics
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      -G Ninja                                                    \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                   \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                          \
      ${ONNXRUNTIME_ROOT:+-DONNXRuntime_DIR=$ONNXRUNTIME_ROOT}    \
      ${LIBJALIENO2_ROOT:+-DlibjalienO2_ROOT=$LIBJALIENO2_ROOT}
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Dependencies
module load ${ONNXRUNTIME_REVISION:+ONNXRuntime/$ONNXRUNTIME_VERSION-$ONNXRUNTIME_REVISION}
# Our environment
set O2PHYSICS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2PHYSICS_ROOT \$O2PHYSICS_ROOT
prepend-path ROOT_INCLUDE_PATH \$O2PHYSICS_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
