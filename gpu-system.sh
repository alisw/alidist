package: gpu-system
version: "error"
allow_system_package_upload: true
prefer_system: .*
prefer_system_check: |
  GPU_FEATURES=
  case $(uname) in
    Darwin*) GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}metal;;
  esac

  # Detect the various GPU features we consider for rebuilding stuff.
  # for now it's just the name. In principle we could put also the (part of) the version

  if command -v /opt/rocm/bin/rocminfo >/dev/null 2>&1 && \
    [[ -d /opt/rocm/ ]] && \
    [[ -d /opt/rocm/lib/cmake ]] && \
    [[ -d /opt/rocm/include/hip ]] && \
    [[ -d /opt/rocm/include/rocprim ]] && \
    [[ -d /opt/rocm/include/thrust ]] && \
    [[ -d /opt/rocm/include/hipcub ]]; then
      GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}rocm
  fi

  if [[ ${GPU_FEATURES} =~ (^|-)"rocm"(-|$) ]] && \
    [[ -d /opt/rocm/include/hiprand ]] && \
    [[ -d /opt/rocm/include/hipblas ]] && \
    [[ -d /opt/rocm/include/hipsparse ]] && \
    [[ -d /opt/rocm/include/hipfft ]] && \
    [[ -d /opt/rocm/include/rocblas ]] && \
    [[ -d /opt/rocm/include/rocrand ]] && \
    [[ -d /opt/rocm/include/miopen ]] && \
    [[ -d /opt/rocm/include/rccl ]] && \
    [[ -d /opt/rocm/lib/hipblaslt ]]; then
      GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}miopen
  fi

  if [[ ${GPU_FEATURES} =~ (^|-)"miopen"(-|$) ]] && \
    [[ -d /opt/rocm/lib/migraphx ]]; then
      GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}migraphx
  fi

  if command -v nvcc >/dev/null 2>&1; then
    GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}cuda
  fi

  if [[ ${GPU_FEATURES} =~ (^|-)"cuda"(-|$) ]] && \
    [[ -f /usr/include/cudnn.h || -f /opt/cuda/targets/x86_64-linux/include/cudnn.h ]]; then
      GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}cudnn
  fi

  if [[ ${GPU_FEATURES} =~ (^|-)"cudnn"(-|$) ]] && \
    [[ ! $(find /usr/lib* /opt/cuda /usr/local/cuda -name "libnvinfer*" -print -quit | wc -l 2>&1) -eq 0 ]]; then
      GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}tensorrt
  fi

  if [[ -z ${GPU_FEATURES} ]]; then
    GPU_FEATURES=none
  fi

  echo "alibuild_system_replace: ${GPU_FEATURES}"

prefer_system_replacement_specs:
  ".*":
    version: "%(key)s"
    recipe: |
      mkdir -p $INSTALLROOT/etc
      rm -f $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_ROCM_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)rocm(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_CUDA_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)cuda(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_MIOPEN_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)miopen(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_CUDNN_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)cudnn(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_MIGRAPHX_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)migraphx(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
      echo "export O2_GPU_TENSORRT_AVAILABLE=$([[ ${PKG_VERSION} =~ (^|-)tensorrt(-|$) ]] && echo 1 || echo 0)" >> $INSTALLROOT/etc/gpu-features-available.sh
---
