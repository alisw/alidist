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
  - xjalienfs
  - O2
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

# Sample dataset: event + settings, calibration objects are recreated below.
# Download only the files used by this test, before spending time compiling.
DATA_DIR=${O2GPUCI_DATA_DIR:-}
if [[ -z $DATA_DIR ]]; then
  for TOKEN_FILE in "${JALIEN_TOKEN_CERT:-}" "${JALIEN_TOKEN_KEY:-}"; do
    if [[ ! -f $TOKEN_FILE || ! -r $TOKEN_FILE ]]; then
      echo "O2-GPU-deterministic-test: set JALIEN_TOKEN_CERT and JALIEN_TOKEN_KEY to readable token files." >&2
      exit 1
    fi
  done
  ALIEN_DATA_DIR=${O2GPUCI_ALIEN_DATA_DIR:-/alice/cern.ch/user/a/alienci/gpuci/events/pbpb-10}
  ALIEN_DATA_DIR=${ALIEN_DATA_DIR#alien://}
  if [[ $ALIEN_DATA_DIR != /* ]]; then
    echo "O2-GPU-deterministic-test: O2GPUCI_ALIEN_DATA_DIR must be an absolute ALIEN catalogue path." >&2
    exit 1
  fi
  DATA_DIR="$BUILDDIR/gpu-standalone-test/data"
  mkdir -p "$DATA_DIR"
  for F in event.0.dump settings.dump tpczslinkmapping.dump; do
    echo "O2-GPU-deterministic-test: downloading ${ALIEN_DATA_DIR%/}/$F"
    if ! alien_cp "alien://${ALIEN_DATA_DIR%/}/$F" "file://$DATA_DIR/$F"; then
      echo "O2-GPU-deterministic-test: ALIEN download failed for $F; check token validity, catalogue access and storage connectivity." >&2
      exit 1
    fi
  done
fi
for F in event.0.dump settings.dump tpczslinkmapping.dump; do
  if [[ ! -s $DATA_DIR/$F ]]; then
    echo "O2-GPU-deterministic-test: $DATA_DIR/$F is missing or empty." >&2
    exit 1
  fi
done
DATA_DIR=$(cd "$DATA_DIR" && pwd -P)
echo "O2-GPU-deterministic-test: dataset ready at $DATA_DIR"

pushd "$BUILDDIR/gpu-standalone-test/build"

cp "$O2_SOURCEDIR/GPU/GPUTracking/Standalone/cmake/config.cmake" .
cat >> config.cmake <<'EoF'
set(GPUCA_BUILD_EVENT_DISPLAY 0)
set(GPUCA_DETERMINISTIC_MODE GPU)
set(GPUCA_DETERMINISTIC_NO_FTZ 1)
set(ENABLE_CUDA OFF)
set(ENABLE_HIP OFF)
set(ENABLE_OPENCL OFF)
EoF

# The standalone defaults use AUTO, which silently builds without a missing
# toolkit. Require each backend being tested so this fails at configure time.
for BACKEND in "${GPU_BACKENDS[@]}"; do
  case ${BACKEND^^} in
    CUDA) echo 'set(ENABLE_CUDA ON)' >> config.cmake ;;
    HIP) echo 'set(ENABLE_HIP ON)' >> config.cmake ;;
    *) echo "O2-GPU-deterministic-test: unsupported GPU backend $BACKEND." >&2; exit 1 ;;
  esac
done

cmake -DCMAKE_INSTALL_PREFIX=../install "$O2_SOURCEDIR/GPU/GPUTracking/Standalone"
cmake --build . --target install -- ${JOBS:+-j $JOBS}

CA=$PWD/../install/ca

print_reproduction()
{
  local BACKEND=$1
  local F
  echo "O2-GPU-deterministic-test: local reproduction instructions ($BACKEND):"
  echo "# Use the same O2 source revision and standalone build settings:"
  echo "# GPUCA_DETERMINISTIC_MODE=GPU, GPUCA_DETERMINISTIC_NO_FTZ=1, and the tested GPU backend enabled."
  echo "# CI executable retained inside the build container: $CA"
  cat <<'EoF'
# Run in a fresh directory containing ./ca and its shared libraries, with the
# required libraries and xjalienfs environment loaded and valid ALIEN credentials.
# Create calibration objects first; download settings and link mapping afterwards.
./ca --recreateTrivialCalibObjects --noEvents --gpuType CPU
EoF
  for F in event.0.dump settings.dump tpczslinkmapping.dump; do
    if [[ -n ${O2GPUCI_DATA_DIR:-} ]]; then
      printf 'cp -- %q ./%s\n' "$DATA_DIR/$F" "$F"
    else
      printf 'alien_cp %q "file://$PWD/%s"\n' "alien://${ALIEN_DATA_DIR%/}/$F" "$F"
    fi
  done
  echo './ca -e . --absoluteEventsDir -c --gpuType CPU --debug 6 --PROCdebugDumpChecksum --seed 0'
  if [[ $BACKEND != CPU ]]; then
    printf './ca -e . --absoluteEventsDir -g --gpuType %q --debug 6 --PROCdebugDumpChecksum --seed 0\n' "$BACKEND"
  fi
}

# Trivial calibration objects, so we do not depend on dumped ones (which can break).
# The flag writes them to the current directory, and a normal run reads them from there.
# Use: o2-gpu-standalone-benchmark from O2 to also re-generate matlut.dump and tpczslinkmapping.dump (not possible with just ./ca)
# The trivial TPCZSLinkMapping is empty and would break decoding of link-based ZS, so take it from the dataset (as well as the settings).
mkdir -p ../calib
if ! (cd ../calib && o2-gpu-standalone-benchmark --recreateTrivialCalibObjects --noEvents --gpuType CPU); then
  echo "O2-GPU-deterministic-test: calibration generation failed." >&2
  print_reproduction CPU
  exit 1
fi
rm -f ../calib/settings.dump

# Debug level 6 with --PROCdebugDumpChecksum computes a SHA1 of the CPU / GPU comparable debug output (clusters, tracks, hex floats)
# on the fly and logs it ("Debug hash: ...") instead of writing the full dump.

run_backend() {
  local BACKEND=$1
  local RUNDIR=../run-$BACKEND
  rm -Rf "$RUNDIR"
  mkdir -p "$RUNDIR"
  ln -s "$PWD"/../calib/*.dump "$RUNDIR"
  ln -s "$DATA_DIR"/{event.0,settings}.dump "$RUNDIR"
  local MODE=-g
  [[ $BACKEND == CPU ]] && MODE=-c
  local LOG
  LOG=$(cd "$RUNDIR" && "$CA" -e . --absoluteEventsDir $MODE --gpuType "$BACKEND" --debug 6 --PROCdebugDumpChecksum --seed 0 2>&1) || {
    echo "O2-GPU-deterministic-test: $BACKEND run failed:" >&2
    tail -n 50 <<< "$LOG" >&2
    print_reproduction "$BACKEND"
    exit 1
  }
  HASH=$(sed -n 's/.*Debug hash: *\([0-9a-fA-F]\{1,\}\).*/\1/p' <<< "$LOG" | tail -n 1)
  if [[ -z $HASH ]]; then
    echo "O2-GPU-deterministic-test: $BACKEND run did not print a debug hash" >&2
    tail -n 50 <<< "$LOG" >&2
    print_reproduction "$BACKEND"
    exit 1
  fi
  echo "O2-GPU-deterministic-test: $BACKEND debug hash $HASH"
}

run_backend CPU
CPU_HASH=$HASH
FAILED=0
for BACKEND in "${GPU_BACKENDS[@]}"; do
  BACKEND=${BACKEND^^}
  run_backend "$BACKEND"
  if [[ $HASH == "$CPU_HASH" ]]; then
    echo "O2-GPU-deterministic-test: $BACKEND output is bit identical to CPU"
  else
    echo "O2-GPU-deterministic-test: $BACKEND output differs from CPU ($HASH vs $CPU_HASH)" >&2
    print_reproduction "$BACKEND"
    FAILED=1
  fi
done
if [[ $FAILED != 0 ]]; then
  exit 1
fi

popd
rm -Rf "$BUILDDIR/gpu-standalone-test"

# Dummy modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
