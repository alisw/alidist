package: O2Physics
version: "%(tag_basename)s"
tag: "nightly-20210818"
requires:
  - O2
  - ONNXRuntime
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/O2Physics
---
#!/bin/sh
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                   \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                   \
      ${ONNXRUNTIME_ROOT:+-DONNXRuntime_DIR=$ONNXRUNTIME_ROOT}
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Dependencies
module load ${ONNXRUNTIME_REVISION:+ONNXRuntime/$ONNXRUNTIME_VERSION-$ONNXRUNTIME_REVISION}
# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
