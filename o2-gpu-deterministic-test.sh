package: O2-GPU-deterministic-test
version: "1.0"
requires:
  - Vc
  - boost
  - fmt
  - ms_gsl
  - TBB
  - ROOT
  - ONNXRuntime
  - GLFW
  - gpu-system
build_requires:
  - CMake
  - Clang
  - ninja
  - alibuild-recipe-tools
license: GPL-3.0
force_rebuild: true
---
#!/bin/bash -e

if [[ -n ${GPU_SYSTEM_ROOT:-} && -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
  source $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh
fi

if [[ -n ${O2GPUCI_BACKENDS:-} ]]; then
  read -r -a GPU_BACKENDS <<< "${O2GPUCI_BACKENDS//,/ }"
else
  GPU_BACKENDS=()
  [[ ${O2_GPU_CUDA_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(CUDA)
  [[ ${O2_GPU_ROCM_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(HIP)
fi

if [[ ${#GPU_BACKENDS[@]} == 0 ]]; then
  echo "O2-GPU-deterministic-test: no GPU backend selected or detected." >&2
  echo "Set O2GPUCI_BACKENDS='CUDA,HIP' in CI to require both production GPU backends." >&2
  exit 1
fi

# HACK to find O2 sources without depending on O2 as a dependency (and potentially building all of it as a consequence)
O2_SOURCEDIR=${O2GPUCI_O2_SOURCEDIR:-}
for SOURCE_CANDIDATE in "$WORK_DIR/../O2" "$ALIBUILD_CONFIG_DIR/../AliceO2"; do
  if [[ -z $O2_SOURCEDIR && -f $SOURCE_CANDIDATE/GPU/GPUTracking/Standalone/CMakeLists.txt ]]; then
    O2_SOURCEDIR=$SOURCE_CANDIDATE
  fi
done
if [[ -z $O2_SOURCEDIR && -d $WORK_DIR/SOURCES/O2 ]]; then
  O2_SOURCEDIR=$(find "$WORK_DIR/SOURCES/O2" -mindepth 2 -maxdepth 2 -type d \
    -exec test -f '{}/GPU/GPUTracking/Standalone/CMakeLists.txt' \; -print -quit 2>/dev/null || true)
fi
if [[ ! -f $O2_SOURCEDIR/GPU/GPUTracking/Standalone/CMakeLists.txt ]]; then
  echo "O2-GPU-deterministic-test: could not find the O2 source tree." >&2
  echo "Set O2GPUCI_O2_SOURCEDIR to the AliceO2 checkout used for this build." >&2
  exit 1
fi

rm -Rf "$BUILDDIR/gpu-standalone-test"
mkdir -p "$BUILDDIR/gpu-standalone-test/build" "$BUILDDIR/gpu-standalone-test/install"
pushd "$BUILDDIR/gpu-standalone-test/build"

cp "$O2_SOURCEDIR/GPU/GPUTracking/Standalone/cmake/config.cmake" .
cat >> config.cmake <<'EoF'
set(GPUCA_BUILD_EVENT_DISPLAY 0)
set(GPUCA_DETERMINISTIC_MODE GPU)
set(GPUCA_DETERMINISTIC_NO_FTZ 1)
EoF

cmake -DCMAKE_INSTALL_PREFIX=../install "$O2_SOURCEDIR/GPU/GPUTracking/Standalone"
cmake --build . --target install -- ${JOBS:+-j $JOBS}

for BACKEND in "${GPU_BACKENDS[@]}"; do
  ../install/ca --noEvents -g --gpuType "${BACKEND^^}"
done

popd
rm -Rf "$BUILDDIR/gpu-standalone-test"

# Dummy modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
