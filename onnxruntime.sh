package: ONNXRuntime
version: "%(tag_basename)s"
tag: v1.29.0
license: MIT
source: https://github.com/microsoft/onnxruntime
requires:
  - protobuf
  - re2
  - boost
  - abseil
  - ms_gsl
  - flatbuffers
  - Eigen3
  - onnx
  - gpu-system
  - "cudnn_frontend:(?!osx)"
  - "cutlass:(?!osx)"
build_requires:
  - date
  - safe_int
  - pytorch_cpuinfo
  - CMake
  - alibuild-recipe-tools
  - nlohmann_json
  - "Python"  # this package builds ONNX, which requires Python
prepend_path:
  ROOT_INCLUDE_PATH: "$ONNXRUNTIME_ROOT/include/onnxruntime"
---
#!/bin/bash -e
rsync -a --chmod=ug=rwX --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

# In order to work with new versions of eigen3, backport
sed -i.bak "s/eigen/Eigen3/g" cmake/external/eigen.cmake
python3 -c 'import sys; print(sys.executable)'
sed -i.bak "s/CMAKE_CXX_STANDARD 17/CMAKE_CXX_STANDARD 20/;s/-Wno-interference-size/-w/" cmake/CMakeLists.txt

case $ARCHITECTURE in
  osx*)
    NLOHMANN_JSON_ROOT=${NLOHMANN_JSON_ROOT:-$(brew --prefix nlohmann-json)}
    RE2_ROOT=${RE2_ROOT:-$(brew --prefix re2)}
    BOOST_ROOT=${BOOST_ROOT:-$(brew --prefix boost)}
    MS_GSL_ROOT=${MS_GSL_ROOT:-$(brew --prefix cpp-gsl)}
  ;;
esac

export re2_DIR=${RE2_ROOT}
export absl_DIR=${ABSEIL_ROOT}
export abseil_cpp_DIR=${ABSEIL_ROOT}
export GSL_DIR=${MS_GSL_ROOT}
export mp11_DIR=${BOOST_ROOT}
export CMAKE_PATH_PREFIX=${MS_GSL_ROOT}:${NLOHMANN_JSON_ROOT}:${ABSEIL_ROOT}:$CMAKE_PATH_PREFIX

if [[ -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
  source $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh
fi

mkdir -p $INSTALLROOT

# Check CUDA CUDNN build conditions
if [[ ${O2_GPU_CUDNN_AVAILABLE:-0} == 1 ]] && [[ -z "$ORT_CUDA_BUILD" ]]; then
  ORT_CUDA_BUILD="1"
else
  ORT_CUDA_BUILD="0"
fi

# Optional GPU features
### MIGraphX
# Upstream removed the ROCm execution provider
# after v1.22, so MIGraphX is the only remaining AMD path and has to stand on
# its own. It needs hip and migraphx from the ROCm installation.
if [[ ${O2_GPU_MIGRAPHX_AVAILABLE:-0} == 1 ]] && [[ -z "$ORT_MIGRAPHX_BUILD" ]]; then
  ORT_MIGRAPHX_BUILD="1"
  LD_LIBRARY_PATH+=$O2_GPU_ROCM_HOME/lib
elif [[ -z "$ORT_MIGRAPHX_BUILD" ]]; then
  ORT_MIGRAPHX_BUILD="0"
fi
### TensorRT
# Also gated on onnx_tensorrt being available. Its provider FetchContents that
# source, which we build with FETCHCONTENT_FULLY_DISCONNECTED=ON and nothing in
# alidist provides -- so on a TensorRT-capable host the configure step fails
# outright. Gating on the root, as with cudnn_frontend and cutlass, turns it
# back on by itself once a recipe supplies one.
if [[ "$ORT_CUDA_BUILD" -eq 1 ]] && [[ ${O2_GPU_TENSORRT_AVAILABLE:-0} == 1 ]] && [[ -n "$ONNX_TENSORRT_ROOT" ]] && [[ -z "$ORT_TENSORRT_BUILD" ]]; then
  ORT_TENSORRT_BUILD="1"
elif [[ -z "$ORT_TENSORRT_BUILD" ]]; then
  ORT_TENSORRT_BUILD="0"
fi

mkdir -p $INSTALLROOT/etc
cat << EOF > $INSTALLROOT/etc/ort-init.sh
export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
EOF

# MIGraphX installs into a self-contained prefix under lib/ on ROCm 6.x
# (/opt/rocm/lib/migraphx/include/migraphx/version.h), which is on no default
# include path: onnxruntime's provider then fails on <migraphx/version.h> even
# though find_package(migraphx) succeeded. Find the prefix and pass it, rather
# than assuming the headers sit beside ROCm's own.
if [[ "$ORT_MIGRAPHX_BUILD" == 1 ]]; then
  for _p in "${O2_GPU_ROCM_HOME:-/opt/rocm}/lib/migraphx" "${O2_GPU_ROCM_HOME:-/opt/rocm}"; do
    if [[ -f "$_p/include/migraphx/version.h" ]]; then
      MIGRAPHX_HOME=$_p
      CXXFLAGS="$CXXFLAGS -isystem $_p/include"
      break
    fi
  done
  echo "MIGRAPHX_HOME=${MIGRAPHX_HOME:-<not found>}"
fi

echo "O2_GPU_ROCM_HOME=$O2_GPU_ROCM_HOME"
echo "O2_GPU_CUDA_HOME=$O2_GPU_CUDA_HOME"

python3 onnxruntime/core/flatbuffers/schema/compile_schema.py --flatc $(which flatc)
python3 onnxruntime/lora/adapter_format/compile_schema.py --flatc $(which flatc)

cmake "cmake"                                                                                               \
      -G Ninja                                                                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                                 \
      -DCMAKE_BUILD_TYPE=Release                                                                            \
      -DCMAKE_INSTALL_LIBDIR=lib                                                                            \
      -DPython_EXECUTABLE="$(python3 -c 'import sys; print(sys.executable)')"                               \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON                                                                  \
      -DFETCHCONTENT_QUIET=OFF                                                                              \
      -DCMAKE_POLICY_DEFAULT_CMP0170=NEW                                                                    \
      -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=ALWAYS                                                           \
      -DCMAKE_SHARED_LINKER_FLAGS='-Wl,-undefined,dynamic_lookup'                                           \
      -DCMAKE_EXE_LINKER_FLAGS='-Wl,-undefined,dynamic_lookup'                                              \
      -Dsafeint_SOURCE_DIR=${SAFE_INT_ROOT}/include                                                         \
      -Deigen_SOURCE_PATH=${EIGEN3_ROOT}/include/eigen3                                                     \
      -DCMAKE_IGNORE_PATH=/opt/homebrew/include                                                             \
      -DGIT_EXECUTABLE=$(type git)                                                                          \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                                                    \
      -Donnxruntime_USE_PREINSTALLED_EIGEN=ON                                                               \
      -Donnxruntime_BUILD_BENCHMARKS=OFF                                                                    \
      -Donnxruntime_BUILD_CSHARP=OFF                                                                        \
      -Donnxruntime_USE_OPENMP=OFF                                                                          \
      -Donnxruntime_USE_TVM=OFF                                                                             \
      -Donnxruntime_USE_LLVM=OFF                                                                            \
      -Donnxruntime_ENABLE_DLPACK=OFF                                                                       \
      -Donnxruntime_USE_NUPHAR=OFF                                                                          \
      -Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF                                                           \
      -Donnxruntime_USE_TENSORRT=${ORT_TENSORRT_BUILD}                                                      \
      -Donnxruntime_TENSORRT_HOME=/usr                                                                      \
      -Donnxruntime_CROSS_COMPILING=OFF                                                                     \
      -Donnxruntime_DISABLE_CONTRIB_OPS=OFF                                                                 \
      -Donnxruntime_PREFER_SYSTEM_LIB=OFF                                                                   \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                                                     \
      -Donnxruntime_USE_VCPKG=OFF                                                                           \
      -DProtobuf_USE_STATIC_LIBS=ON                                                                         \
      -Donnxruntime_ENABLE_TRAINING=OFF                                                                     \
      -Donnxruntime_USE_FULL_PROTOBUF=ON                                                                    \
      -Donnxruntime_ENABLE_PYTHON=OFF                                                                       \
      -Donnxruntime_MINIMAL_BUILD=OFF                                                                       \
      --debug-find-pkg=absl                                                                                 \
      ${ABSEIL_ROOT:+-DFETCHCONTENT_SOURCE_DIR_ABSEIL_CPP=${ABSEIL_ROOT}}                                   \
      ${ABSEIL_ROOT:+-Dabseil_cpp_DIR=$ABSEIL_ROOT}                                                         \
      ${ABSEIL_ROOT:+-Dabsl_DIR=$ABSEIL_ROOT}                                                               \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a}                                 \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a}                       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a}                            \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                                       \
      ${PROTOBUF_ROOT:+-DONNX_CUSTOM_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}                           \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}                                                    \
      ${BOOST_ROOT:+-DBOOST_INCLUDE_DIR=${BOOST_ROOT}/include}                                              \
      ${BOOST_ROOT:+-DFETCHCONTENT_SOURCE_DIR_MP11=${BOOST_ROOT}}                                            \
      -Donnxruntime_USE_MIGRAPHX=${ORT_MIGRAPHX_BUILD}                                                      \
      ${MIGRAPHX_HOME:+-DAMD_MIGRAPHX_HOME=${MIGRAPHX_HOME}}                                                \
      -Donnxruntime_ROCM_HOME=${O2_GPU_ROCM_HOME}                                                           \
      -Donnxruntime_CUDA_HOME=${O2_GPU_CUDA_HOME}                                                           \
      -DCMAKE_HIP_COMPILER=/opt/rocm/llvm/bin/clang++                                                       \
      ${O2_GPU_ROCM_AVAILABLE_ARCH:+-DCMAKE_HIP_ARCHITECTURES="${O2_GPU_ROCM_AVAILABLE_ARCH}"}              \
      ${O2_GPU_CUDA_AVAILABLE_ARCH:+-DCMAKE_CUDA_ARCHITECTURES="${O2_GPU_CUDA_AVAILABLE_ARCH}"}             \
      -Donnxruntime_DISABLE_RTTI=OFF                                                                        \
      -DMSVC=OFF                                                                                            \
      -Donnxruntime_USE_CUDA=${ORT_CUDA_BUILD}                                                              \
      -Donnxruntime_USE_CUDA_NHWC_OPS=${ORT_CUDA_BUILD}                                                     \
      ${CUDNN_FRONTEND_ROOT:+-DFETCHCONTENT_SOURCE_DIR_CUDNN_FRONTEND=${CUDNN_FRONTEND_ROOT}}             \
      ${CUTLASS_ROOT:+-DFETCHCONTENT_SOURCE_DIR_CUTLASS=${CUTLASS_ROOT}}                                   \
      ${ONNX_TENSORRT_ROOT:+-DFETCHCONTENT_SOURCE_DIR_ONNX_TENSORRT=${ONNX_TENSORRT_ROOT}}           \
      -Donnxruntime_FUZZ_ENABLED=OFF                                                                        \
      -Donnxruntime_USE_FLASH_ATTENTION=OFF                                                                 \
      -Donnxruntime_USE_LEAN_ATTENTION=OFF                                                                  \
      -Donnxruntime_USE_MEMORY_EFFICIENT_ATTENTION=ON                                                       \
      -DCMAKE_CUDA_FLAGS="${CXXFLAGS} -Wno-error=deprecated-enum-float-conversion -Wno-error -Wno-error=missing-requires -w" \
      -DCMAKE_HIP_FLAGS="${CXXFLAGS} -Wno-error=deprecated-enum-float-conversion -Wno-error -Wno-error=missing-requires -w" \
      -DCMAKE_CXX_FLAGS="${CXXFLAGS} -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated -Wno-error=maybe-uninitialized -Wno-error=deprecated-enum-enum-conversion -Wno-error -Wno-error=missing-requires -w" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-pass-failed -Wno-error=unused-but-set-variable -Wno-pass-failed=transform-warning -Wno-error=deprecated -Wno-error=maybe-uninitialized -Wno-error=deprecated-enum-enum-conversion -Wno-error -Wno-error=missing-requires -w"

if [[ "$ORT_TENSORRT_BUILD" -eq 1 ]]; then
  # onnx-tensorrt forces C++17 after our C++20 flags. The external Abseil package
  # uses std::*_ordering, so compile the fetched parser with C++20 as well.
  sed -i.bak "s/set(CMAKE_CXX_STANDARD 17)/set(CMAKE_CXX_STANDARD 20)/" \
    _deps/onnx_tensorrt-src/CMakeLists.txt

  # The TensorRT 10.9 parser revision uses ONNX's FLOAT4E2M1 enum, which was
  # introduced after the ONNX 1.17 version pinned by ONNX Runtime 1.22. Disable
  # only those FP4 conversion paths; INT4 and all other parser support remains.
  sed -i.bak \
    -e '/case .*FLOAT4E2M1/d' \
    -e 's/ || onnxDtype == ::ONNX_NAMESPACE::TensorProto::FLOAT4E2M1//g' \
    _deps/onnx_tensorrt-src/TensorOrWeights.cpp \
    _deps/onnx_tensorrt-src/weightUtils.cpp \
    _deps/onnx_tensorrt-src/WeightsContext.cpp \
    _deps/onnx_tensorrt-src/importerUtils.cpp
fi

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/onnxruntime
EoF
