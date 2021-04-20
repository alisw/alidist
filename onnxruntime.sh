package: onnxruntime
version: "%(tag_basename)s"
tag: 1.7.2
source: https://github.com/microsoft/onnxruntime.git
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
 - Python-modules
 - re2
 - protobuf
---
# TODO: should be: git clone --recurse-submodules, how to pass git option?

mkdir -p $INSTALLROOT
cmake -Donnxruntime_DEV_MODE=OFF \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON \
      -Donnxruntime_ENABLE_PYTHON=ON \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -Deigen_SOURCE_PATH=/usr/include/eigen3 \
      -Donnxruntime_USE_PREINSTALLED_EIGEN=ON \
      -Donnxruntime_BUILD_SHARED_LIB=ON \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" "$SOURCEDIR/cmake"

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set onnxruntime_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$onnxruntime_ROOT/lib
EoF
