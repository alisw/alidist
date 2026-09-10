#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODEL=${1:-${SCRIPT_DIR}/../test/onnxruntime-inference/net.onnx}
if [[ ! -f $MODEL ]]; then
  echo "onnxruntime-inference-test: model not found: $MODEL" >&2
  exit 2
fi

IFS=', ' read -r -a PROVIDERS <<< "${ONNXRUNTIME_INFERENCE_TEST_PROVIDERS:-cpu,migraphx,cuda}"

FAILURES=()
for PROVIDER in "${PROVIDERS[@]}"; do
  [[ -n $PROVIDER ]] || continue
  PROVIDER=${PROVIDER,,}
  echo "onnxruntime-inference-test: running ${PROVIDER}"
  if ! "${SCRIPT_DIR}/run-onnxruntime-${PROVIDER}.sh" "$MODEL"; then
    FAILURES+=("$PROVIDER")
  fi
done

if [[ ${#FAILURES[@]} != 0 ]]; then
  echo "onnxruntime-inference-test: failed providers: ${FAILURES[*]}" >&2
  exit 1
fi

echo "onnxruntime-inference-test: all providers passed"
