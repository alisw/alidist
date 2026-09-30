package: llamacpp
version: "%(tag_basename)s"
tag: b11160
license: MIT
source: https://github.com/ggml-org/llama.cpp
requires:
  - gpu-system
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e

# RPATH, so llama-server finds its own libraries without LD_LIBRARY_PATH: built
# with BUILD_SHARED_LIBS=ON a bare exec otherwise dies with "error while loading
# shared libraries". The modulefile covers alienv users; this covers the rest.
case $ARCHITECTURE in
  osx*) LLAMA_RPATH='@loader_path/../lib' ;;
  *)    LLAMA_RPATH='$ORIGIN/../lib' ;;
esac
LLAMA_RPATH_ARGS=(-DCMAKE_INSTALL_RPATH="$LLAMA_RPATH" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON)

# GPU backend: Metal on Apple, HIP where gpu-system found ROCm, CPU otherwise.
# ROCm does not exist on macOS, so the HIP branch must not be reachable there.
LLAMA_GPU_ARGS=()
if [[ $ARCHITECTURE == osx* ]]; then
  LLAMA_GPU_ARGS=(-DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON)
elif [[ ${O2_GPU_ROCM_AVAILABLE:-0} == 1 ]]; then
  # gfx906 (MI50) rocBLAS kernels are all but gone from ROCm >= 6.4: build against
  # 6.3 or the link succeeds and the first GEMM does not.
  ARCHS=${LLAMACPP_AMDGPU_TARGETS:-${O2_GPU_ROCM_AVAILABLE_ARCH:-$GPU_HIP_ARCHITECTURE}}
  LLAMA_GPU_ARGS=(-DGGML_HIP=ON
                  -DGPU_TARGETS="$ARCHS"
                  -DAMDGPU_TARGETS="$ARCHS"   # legacy spelling; forwarded pre-b11xxx
                  -DCMAKE_C_COMPILER="$O2_GPU_ROCM_HOME/llvm/bin/clang"
                  -DCMAKE_CXX_COMPILER="$O2_GPU_ROCM_HOME/llvm/bin/clang++")
fi

cmake "$SOURCEDIR"                                     \
  -DCMAKE_BUILD_TYPE=Release                           \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                \
  -DLLAMA_CURL=OFF                                     \
  -DLLAMA_BUILD_TESTS=OFF                              \
  -DBUILD_SHARED_LIBS=ON                               \
  "${LLAMA_RPATH_ARGS[@]}"                             \
  "${LLAMA_GPU_ARGS[@]}"                               \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}

cmake --build . ${JOBS:+-j $JOBS} --target install

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
