package: onnxruntime
version: "%(tag_basename)s"
tag: master
source: https://github.com/microsoft/onnxruntime
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
---
cmake -Donnxruntime_DEV_MODE=OFF \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -Deigen_SOURCE_PATH=/usr/include/eigen3 \
      -Donnxruntime_USE_PREINSTALLED_EIGEN=ON \
      -Donnxruntime_BUILD_SHARED_LIB=ON \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" "$SOURCEDIR/cmake"

