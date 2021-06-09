package: onnxruntime
version: "1.7.2"
tag: c073c88ef
source: https://github.com/saganatt/onnxruntime.git
requires:
  - protobuf
  - re2
build_requires:
  - CMake
---
#!/bin/bash -e

pushd $SOURCEDIR
  git submodule update --init -- cmake/external/date
  git submodule update --init -- cmake/external/mp11
  git submodule update --init -- cmake/external/onnx
  git submodule update --init -- cmake/external/optional-lite
  git submodule update --init -- cmake/external/eigen
  git submodule update --init -- cmake/external/nsync
  git submodule update --init -- cmake/external/flatbuffers
  git submodule update --init -- cmake/external/SafeInt
  git submodule update --init -- cmake/external/json
popd

mkdir -p $INSTALLROOT

# NOTE: It builds its own flatbuffers, eigen, nsync, pybind11
cmake "$SOURCEDIR/cmake" \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -Donnxruntime_DEV_MODE=OFF \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF \
      -Donnxruntime_ENABLE_PYTHON=ON \
      -DPYTHON_EXECUTABLE=$(python3 -c "import sys; print(sys.executable)") \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON \
      -Donnxruntime_BUILD_SHARED_LIB=ON \
      -DProtobuf_USE_STATIC_LIBS=ON \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc} \
      -Donnxruntime_USE_PREINSTALLED_NSYNC=OFF \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$${PKGNAME}_ROOT/lib
EoF
