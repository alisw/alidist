package: O2-GPU-test
version: "1.0"
requires:
  - O2
  - ONNXRuntime
  - gpu-system
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
license: GPL-3.0
force_rebuild: true
---
#!/bin/bash -e

if [[ -n ${GPU_SYSTEM_ROOT:-} && -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
  source $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh
fi

rm -Rf $BUILDDIR/gpu-test
mkdir $BUILDDIR/gpu-test
pushd $BUILDDIR/gpu-test

if [[ -n ${O2GPUCI_BACKENDS:-} ]]; then
  read -r -a GPU_BACKENDS <<< "${O2GPUCI_BACKENDS//,/ }"
else
  GPU_BACKENDS=()
  [[ ${O2_GPU_CUDA_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(CUDA)
  [[ ${O2_GPU_ROCM_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(HIP)
fi

if [[ ${#GPU_BACKENDS[@]} == 0 ]]; then
  echo "O2-GPU-test: no GPU backend selected or detected." >&2
  exit 1
fi

for BACKEND in "${GPU_BACKENDS[@]}"; do
  o2-gpu-standalone-benchmark --noEvents -g --gpuType "${BACKEND^^}"
done

popd
rm -Rf $BUILDDIR/gpu-test

# ONNXRuntime execution-provider inference test (CPU + CUDA/TensorRT/MIGraphX,
# depending on the backends above). The test lives in the O2 sources, so find
# the O2 checkout the same way O2-GPU-deterministic-test does.
O2_SOURCEDIR=${O2GPUCI_O2_SOURCEDIR:-}
for SOURCE_CANDIDATE in "$WORK_DIR/../O2" "$ALIBUILD_CONFIG_DIR/../AliceO2"; do
  if [[ -z $O2_SOURCEDIR && -f $SOURCE_CANDIDATE/Common/ML/test/onnxruntime-inference/run-ci-onnxruntime-inference-test.sh ]]; then
    O2_SOURCEDIR=$SOURCE_CANDIDATE
  fi
done
if [[ -z $O2_SOURCEDIR && -d $WORK_DIR/SOURCES/O2 ]]; then
  O2_SOURCEDIR=$(find "$WORK_DIR/SOURCES/O2" -mindepth 2 -maxdepth 2 -type d \
    -exec test -f '{}/Common/ML/test/onnxruntime-inference/run-ci-onnxruntime-inference-test.sh' \; -print -quit 2>/dev/null || true)
fi
if [[ ! -f $O2_SOURCEDIR/Common/ML/test/onnxruntime-inference/run-ci-onnxruntime-inference-test.sh ]]; then
  echo "O2-GPU-test: could not find the O2 source tree with the ONNXRuntime inference test." >&2
  echo "Set O2GPUCI_O2_SOURCEDIR to the AliceO2 checkout used for this build." >&2
  exit 1
fi

"$O2_SOURCEDIR/Common/ML/test/onnxruntime-inference/run-ci-onnxruntime-inference-test.sh" "$O2_SOURCEDIR"

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
