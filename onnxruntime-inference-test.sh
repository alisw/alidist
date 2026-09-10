package: ONNXRuntime-inference-test
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

MODEL=${ONNXRUNTIME_INFERENCE_TEST_MODEL:-$ALIBUILD_CONFIG_DIR/resources/onnxruntime-inference-test/net.onnx}
if [[ ! -f $MODEL ]]; then
  echo "ONNXRuntime-inference-test: model not found: $MODEL" >&2
  exit 1
fi

echo "ONNXRuntime-inference-test: ORT_CUDA_BUILD=${ORT_CUDA_BUILD:-unset}"
echo "ONNXRuntime-inference-test: ORT_MIGRAPHX_BUILD=${ORT_MIGRAPHX_BUILD:-unset}"
echo "ONNXRuntime-inference-test: ORT_TENSORRT_BUILD=${ORT_TENSORRT_BUILD:-unset}"
echo "ONNXRuntime-inference-test: model=$MODEL"

rm -Rf "$BUILDDIR/onnxruntime-inference-test"
mkdir -p "$BUILDDIR/onnxruntime-inference-test/build" "$BUILDDIR/onnxruntime-inference-test/src"
rsync -a "$ALIBUILD_CONFIG_DIR/resources/onnxruntime-inference-test/" "$BUILDDIR/onnxruntime-inference-test/src/"

pushd "$BUILDDIR/onnxruntime-inference-test/build"
cmake -G Ninja \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -Donnxruntime_DIR="$ONNXRUNTIME_ROOT/lib/cmake/onnxruntime" \
      ../src
cmake --build . --target install -- ${JOBS:+-j $JOBS}

export ONNXRUNTIME_INFERENCE_TEST_BINARY="$INSTALLROOT/bin/onnxruntime-ep-inference"
"$INSTALLROOT/bin/run-onnxruntime-all-eps.sh" "$MODEL"

popd
rm -Rf "$BUILDDIR/onnxruntime-inference-test"

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
