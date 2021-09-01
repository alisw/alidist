package: O2Physics
version: "%(tag_basename)s"
tag: "nightly-20210824"
requires:
  - O2
  - ONNXRuntime
  - libjalienO2
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/O2Physics
---
#!/bin/sh
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      -G Ninja                                                    \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                   \
      ${ONNXRUNTIME_ROOT:+-DONNXRuntime_DIR=$ONNXRUNTIME_ROOT}    \
      ${LIBJALIENO2_ROOT:+-DlibjalienO2_ROOT=$LIBJALIENO2_ROOT}
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Dependencies
module load ${ONNXRUNTIME_REVISION:+ONNXRuntime/$ONNXRUNTIME_VERSION-$ONNXRUNTIME_REVISION}
# Our environment
setenv O2PHYSICS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
