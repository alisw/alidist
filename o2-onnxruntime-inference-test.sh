package: O2-ONNXRuntime-inference-test
version: "1.0"
requires:
  - ONNXRuntime
  - gpu-system
build_requires:
  - CMake
  - Clang
  - ninja
  - alibuild-recipe-tools
license: GPL-3.0
force_rebuild: true
valid_defaults:
  - o2
  - o2-epn
  - ali
---
#!/bin/bash -e

if [[ -n ${GPU_SYSTEM_ROOT:-} && -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
  source "$GPU_SYSTEM_ROOT/etc/gpu-features-available.sh"
fi
if [[ -n ${ONNXRUNTIME_ROOT:-} && -f $ONNXRUNTIME_ROOT/etc/ort-init.sh ]]; then
  source "$ONNXRUNTIME_ROOT/etc/ort-init.sh"
fi

if [[ -n ${O2GPUCI_BACKENDS:-} ]]; then
  read -r -a GPU_BACKENDS <<< "${O2GPUCI_BACKENDS//,/ }"
else
  GPU_BACKENDS=()
  [[ ${O2_GPU_CUDA_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(CUDA)
  [[ ${O2_GPU_ROCM_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(HIP)
fi

if [[ ${#GPU_BACKENDS[@]} == 0 ]]; then
  echo "O2-ONNXRuntime-inference-test: no GPU backend selected or detected." >&2
  echo "Set O2GPUCI_BACKENDS='CUDA,HIP' in CI to require both production GPU backends." >&2
  exit 1
fi

# HACK to find O2 sources without depending on O2 as a dependency (and potentially building all of it as a consequence)
O2_SOURCEDIR=${O2GPUCI_O2_SOURCEDIR:-}
for SOURCE_CANDIDATE in "$WORK_DIR/../O2" "$ALIBUILD_CONFIG_DIR/../AliceO2"; do
  if [[ -z $O2_SOURCEDIR && -f $SOURCE_CANDIDATE/Common/ML/test/onnxruntime-inference/run-local-onnxruntime-inference-test.sh ]]; then
    O2_SOURCEDIR=$SOURCE_CANDIDATE
  fi
done
if [[ -z $O2_SOURCEDIR && -d $WORK_DIR/SOURCES/O2 ]]; then
  O2_SOURCEDIR=$(find "$WORK_DIR/SOURCES/O2" -mindepth 2 -maxdepth 2 -type d \
    -exec test -f '{}/Common/ML/test/onnxruntime-inference/run-local-onnxruntime-inference-test.sh' \; -print -quit 2>/dev/null || true)
fi
if [[ ! -f $O2_SOURCEDIR/Common/ML/test/onnxruntime-inference/run-local-onnxruntime-inference-test.sh ]]; then
  echo "O2-ONNXRuntime-inference-test: could not find the O2 source tree." >&2
  echo "Set O2GPUCI_O2_SOURCEDIR to the AliceO2 checkout used for this build." >&2
  exit 1
fi

PROVIDERS=(cpu)
for BACKEND in "${GPU_BACKENDS[@]}"; do
  case "${BACKEND^^}" in
    CUDA)
      if [[ ${ORT_CUDA_BUILD:-0} == 1 ]]; then
        PROVIDERS+=(cuda)
      fi
      if [[ ${ORT_TENSORRT_BUILD:-0} == 1 ]]; then
        PROVIDERS+=(tensorrt)
      fi
      ;;
    HIP|ROCM)
      if [[ ${ORT_MIGRAPHX_BUILD:-0} == 1 ]]; then
        PROVIDERS+=(migraphx)
      fi
      ;;
    *)
      echo "O2-ONNXRuntime-inference-test: unsupported backend requested: $BACKEND" >&2
      exit 1
      ;;
  esac
done

if [[ ${#PROVIDERS[@]} == 1 ]]; then
  echo "O2-ONNXRuntime-inference-test: no ONNXRuntime GPU execution provider was selected." >&2
  echo "ORT_CUDA_BUILD=${ORT_CUDA_BUILD:-0}, ORT_TENSORRT_BUILD=${ORT_TENSORRT_BUILD:-0}, ORT_MIGRAPHX_BUILD=${ORT_MIGRAPHX_BUILD:-0}" >&2
  exit 1
fi

ONNXRUNTIME_INFERENCE_TEST_PROVIDERS=$(IFS=,; echo "${PROVIDERS[*]}") \
  "$O2_SOURCEDIR/Common/ML/test/onnxruntime-inference/run-local-onnxruntime-inference-test.sh"

# Dummy modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
