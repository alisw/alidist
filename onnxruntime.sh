package: ONNXRuntime
version: "%(tag_basename)s"
tag: v1.19.0
source: https://github.com/microsoft/onnxruntime
requires:
  - protobuf
  - re2
  - boost
  - abseil
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"  # this package builds ONNX, which requires Python
  - "Python-system:(?!slc.*|ubuntu)"
prepend_path:
  ROOT_INCLUDE_PATH: "$ONNXRUNTIME_ROOT/include/onnxruntime"
---
#!/bin/bash -e

mkdir -p $INSTALLROOT

ORT_BUILD_FLAGS=""
case $ARCHITECTURE in
  osx_*)
    if [[ $ARCHITECTURE == *_x86-64 ]]; then
      echo "Installing ONNXRuntime for MacOS (CPU version)"
    else
      echo "Installing ONNXRuntime for MacOS (Metal backend)"
    fi
  ;;
  *)
    if command -v rocminfo >/dev/null 2>&1; then
      echo "Enabling ONNXRuntime build for ROCm"
      export ORT_ROCM_BUILD=1
      if command -v find /opt/rocm* -name "libmigraphx*" >/dev/null 2>&1; then
        echo "  - ROCm build with MIGraphX"
        export ORT_MIGRAPHX_BUILD=1
        ORT_BUILD_FLAGS="${ORT_BUILD_FLAGS} -Donnxruntime_USE_MIGRAPHX=ON"
      fi
      ORT_BUILD_FLAGS="${ORT_BUILD_FLAGS}                                                             \
                      -Donnxruntime_USE_ROCM=ON                                                       \
                      -Donnxruntime_ROCM_HOME=/opt/rocm                                               \
                      -DCMAKE_HIP_COMPILER=/opt/rocm/llvm/bin/clang++                                 \
                      -D__HIP_PLATFORM_AMD__=1                                                        \
                      -DCMAKE_HIP_ARCHITECTURES=gfx906,gfx908                                         \
                      -Donnxruntime_USE_COMPOSABLE_KERNEL=OFF                                         \
                      -Donnxruntime_USE_ROCBLAS_EXTENSION_API=ON                                      \
                      -Donnxruntime_USE_COMPOSABLE_KERNEL_CK_TILE=ON                                  \
                      -Donnxruntime_DISABLE_RTTI=OFF                                                  \
                      -Donnxruntime_ENABLE_TRAINING=OFF                                               \
                      -DMSVC=OFF                                                                      \
                      "
    elif command -v nvcc >/dev/null 2>&1; then
      CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $NF}' | cut -dV -f2)
      export ORT_CUDA_BUILD=1
      # if [[ "$CUDA_VERSION" == "V11" ]]; then
      echo "Enabling ONNXRuntime build for CUDA (version ${CUDA_VERSION})"
      ORT_BUILD_FLAGS="${ORT_BUILD_FLAGS}                                                            \
                      -Donnxruntime_USE_CUDA=ON                                                      \
                      -Donnxruntime_USE_CUDA_NHWC_OPS=ON                                             \
                      "
      if command -v 'find /usr -name "libnvinfer*"' >/dev/null 2>&1; then
        ORT_BUILD_FLAGS="${ORT_BUILD_FLAGS} -Donnxruntime_CUDA_USE_TENSORRT=ON"
      fi
    else
      echo "Building ONNXRuntime basic CPU version"
      export ORT_CPU_BUILD=1
    fi
  ;;
esac

cmake "$SOURCEDIR/cmake"                                                              \
      $ORT_BUILD_FLAGS                                                                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                             \
      -DCMAKE_BUILD_TYPE=Release                                                      \
      -DCMAKE_INSTALL_LIBDIR=lib                                                      \
      -DPYTHON_EXECUTABLE=$(python3 -c "import sys; print(sys.executable)")           \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                              \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON                                              \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                               \
      -DProtobuf_USE_STATIC_LIBS=ON                                                   \
      -Donnxruntime_ENABLE_TRAINING=OFF                                               \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a}           \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a}      \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                 \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}        \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}                              \
      ${BOOST_ROOT:+-DBOOST_INCLUDE_DIR=${BOOST_ROOT}/include}                        \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated"

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/onnxruntime
EoF
