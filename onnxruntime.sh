package: ONNXRuntime
version: "%(tag_basename)s"
tag: v1.20.0
source: https://github.com/microsoft/onnxruntime
requires:
  - protobuf
  - re2
  - boost
  - abseil
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python"  # this package builds ONNX, which requires Python
prepend_path:
  ROOT_INCLUDE_PATH: "$ONNXRUNTIME_ROOT/include/onnxruntime"
---
#!/bin/bash -e

mkdir -p $INSTALLROOT

# Check ROCm build conditions
if [[ -f /etc/redhat-release ]]; then
  export ALMA_LINUX_MAJOR_VERSION=$(awk '{print $3}' /etc/redhat-release | cut -d. -f1)
fi

if [[ "$ALIBUILD_O2_FORCE_GPU" -eq 1 ]] || [[ "$ALIBUILD_ENABLE_HIP" -eq 1 ]] || \
  ( ( [[ -z "$DISABLE_GPU" ]] || [[ "$DISABLE_GPU" -eq 0 ]] ) && \
  ( command -v /opt/rocm/bin/rocminfo >/dev/null 2>&1 ) && \
  [[ -d /opt/rocm/include/hiprand ]] && \
  [[ -d /opt/rocm/include/hipblas ]] && \
  [[ -d /opt/rocm/include/hipsparse ]] && \
  [[ -d /opt/rocm/include/hipfft ]] && \
  [[ -d /opt/rocm/include/rocblas ]] && \
  [[ -d /opt/rocm/include/rocrand ]] && \
  [[ -d /opt/rocm/include/miopen ]] && \
  [[ -d /opt/rocm/include/rccl ]] && \
  [[ -d /opt/rocm/lib/hipblaslt ]] && \
  [[ -z "$ORT_ROCM_BUILD" ]] ) && \
  ([[ -z "$ALMA_LINUX_MAJOR_VERSION" ]] || [[ "$ALMA_LINUX_MAJOR_VERSION" -eq 9 ]]); then
  export ORT_ROCM_BUILD="1"
  : ${ALIBUILD_O2_OVERRIDE_HIP_ARCHS:="gfx906,gfx908"}
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib
else
  export ORT_ROCM_BUILD="0"
fi

# Check CUDA build conditions
if ( [[ "$ALIBUILD_O2_FORCE_GPU" -eq 1 ]] || [[ "$ALIBUILD_ENABLE_CUDA" -eq 1 ]] || \
  ( ( [[ -z "$DISABLE_GPU" ]] || [[ "$DISABLE_GPU" -eq 0 ]] ) && \
  ( command -v nvcc >/dev/null 2>&1 ) && \
  [[ -f /usr/include/cudnn.h ]] && \
  [[ -z "$ORT_CUDA_BUILD" ]] ) ) && \
  [[ "$ORT_ROCM_BUILD" -eq 0 ]] && \
  [[ -z "$ALMA_LINUX_MAJOR_VERSION" ]]; then
  export ORT_CUDA_BUILD="1"
  : ${ALIBUILD_O2_OVERRIDE_CUDA_ARCHS:="sm_86"}
else
  export ORT_CUDA_BUILD="0"
fi

# Optional builds
### MIGraphX
if ( [[ "$ORT_ROCM_BUILD" -eq 1 ]] && [[ $(find /opt/rocm* -name "libmigraphx*" -print -quit | wc -l 2>&1) -eq 1 ]] ) && \
   [[ -z "$ORT_MIGRAPHX_BUILD" ]]; then
  export ORT_MIGRAPHX_BUILD="1"
elif [[ -z "$ORT_MIGRAPHX_BUILD" ]]; then
  export ORT_MIGRAPHX_BUILD="0"
fi
### TensorRT
if ( [[ "$ORT_CUDA_BUILD" -eq 1 ]] && [[ $(find /usr -name "libnvinfer*" -print -quit | wc -l 2>&1) -eq 1 ]] ) && \
   [[ -z "$ORT_MIGRAPHX_BUILD" ]]; then
  export ORT_TENSORRT_BUILD="1"
elif [[ -z "$ORT_TENSORRT_BUILD" ]]; then
  export ORT_TENSORRT_BUILD="0"
fi

mkdir -p $INSTALLROOT/etc
cat << EOF > $INSTALLROOT/etc/ort-init.sh
export ORT_ROCM_BUILD=$ORT_ROCM_BUILD
export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
EOF

cmake "$SOURCEDIR/cmake"                                                                                    \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                                   \
      -DCMAKE_BUILD_TYPE=Release                                                                            \
      -DCMAKE_INSTALL_LIBDIR=lib                                                                            \
      -DPYTHON_EXECUTABLE=$(python3 -c "import sys; print(sys.executable)")                                 \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                                                    \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON                                                                    \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                                                     \
      -DProtobuf_USE_STATIC_LIBS=ON                                                                         \
      -Donnxruntime_ENABLE_TRAINING=OFF                                                                     \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a}                                 \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a}                       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a}                            \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                                       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}                              \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}                                                    \
      ${BOOST_ROOT:+-DBOOST_INCLUDE_DIR=${BOOST_ROOT}/include}                                              \
      -Donnxruntime_USE_MIGRAPHX=${ORT_MIGRAPHX_BUILD}                                                      \
      -Donnxruntime_USE_ROCM=${ORT_ROCM_BUILD}                                                              \
      -Donnxruntime_ROCM_HOME=/opt/rocm                                                                     \
      -Donnxruntime_CUDA_HOME=/usr/local/cuda                                                               \
      -DCMAKE_HIP_COMPILER=/opt/rocm/llvm/bin/clang++                                                       \
      -D__HIP_PLATFORM_AMD__=${ORT_ROCM_BUILD}                                                              \
      ${ALIBUILD_O2_OVERRIDE_HIP_ARCHS:+-DCMAKE_HIP_ARCHITECTURES=${ALIBUILD_O2_OVERRIDE_HIP_ARCHS}}        \
      ${ALIBUILD_O2_OVERRIDE_CUDA_ARCH:+-CMAKE_CUDA_ARCHITECTURES=${ALIBUILD_O2_OVERRIDE_CUDA_ARCHS}}       \
      -Donnxruntime_USE_COMPOSABLE_KERNEL=OFF                                                               \
      -Donnxruntime_USE_ROCBLAS_EXTENSION_API=${ORT_ROCM_BUILD}                                             \
      -Donnxruntime_USE_COMPOSABLE_KERNEL_CK_TILE=ON                                                        \
      -Donnxruntime_DISABLE_RTTI=OFF                                                                        \
      -DMSVC=OFF                                                                                            \
      -Donnxruntime_USE_CUDA=${ORT_CUDA_BUILD}                                                              \
      -Donnxruntime_USE_CUDA_NHWC_OPS=${ORT_CUDA_BUILD}                                                     \
      -Donnxruntime_CUDA_USE_TENSORRT=${ORT_TENSORRT_BUILD}                                                 \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated -Wno-error=maybe-uninitialized" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated -Wno-error=maybe-uninitialized"

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/onnxruntime
append-path LD_LIBRARY_PATH /opt/rocm/lib
EoF
