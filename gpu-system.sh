package: gpu-system
version: "1.0"
prefer_system: .*
prefer_system_check: |
  case $(uname) in
    Darwin*) echo alibuild_system_replace: metal ;;
  esac

  # Detect the various GPU features we consider for rebuilding stuff.
  # for now it's just the name. In principle we could put also the (part of) the version
  GPU_FEATURES=
  if command -v /opt/rocm/bin/rocminfo >/dev/null 2>&1 && \
    [[ -d /opt/rocm/include/hiprand ]] && \
    [[ -d /opt/rocm/include/hipblas ]] && \
    [[ -d /opt/rocm/include/hipsparse ]] && \
    [[ -d /opt/rocm/include/hipfft ]] && \
    [[ -d /opt/rocm/include/rocblas ]] && \
    [[ -d /opt/rocm/include/rocrand ]] && \
    [[ -d /opt/rocm/include/miopen ]] && \
    [[ -d /opt/rocm/include/rccl ]] && \
    [[ -d /opt/rocm/lib/hipblaslt ]]; then
        GPU_FEATURES=rocm
  fi

  if command -v nvcc >/dev/null 2>&1 && \
    [[ -f /usr/include/cudnn.h ]] && \
    [[ -z "$ORT_CUDA_BUILD" ]] && \
    [[ "$ORT_ROCM_BUILD" -eq 0 ]] && \
    [[ -z "$ALMA_LINUX_MAJOR_VERSION" ]]; then
        GPU_FEATURES=${GPU_FEATURES:+${GPU_FEATURES}-}cuda
  fi

  if [ "X$GPU_FEATURES" = "" ]; then
    echo "alibuild_system_replace: none"
  fi

prefer_system_replacement_specs:
  "metal.*":
    version: "%(key)s"
    recipe: |
      mkdir -p $INSTALLROOT/etc
      cat << EOF > $INSTALLROOT/etc/gpu-init.sh
      EOF
  "none":
    version: "%(key)s"
  "rocm-cuda":
    version: "%(key)s"
    env:
      ORT_CUDA_BUILD=1
      ORT_ROCM_BUILD=1
    recipe: |
      mkdir -p $INSTALLROOT/etc
      cat << EOF > $INSTALLROOT/etc/gpu-init.sh
      export ORT_ROCM_BUILD=$ORT_ROCM_BUILD
      export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
      export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
      export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
      EOF
  "rocm":
    version: "%(key)s"
    env:
      ORT_CUDA_BUILD=0
      ORT_ROCM_BUILD=1
    recipe: |
      mkdir -p $INSTALLROOT/etc
      cat << EOF > $INSTALLROOT/etc/gpu-init.sh
      export ORT_ROCM_BUILD=$ORT_ROCM_BUILD
      export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
      export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
      export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
      EOF
  "cuda":
    version: "%(key)s"
    env: 
      ORT_CUDA_BUILD=1
      ORT_ROCM_BUILD=0
    recipe: |
      mkdir -p $INSTALLROOT/etc
      cat << EOF > $INSTALLROOT/etc/gpu-init.sh
      export ORT_ROCM_BUILD=$ORT_ROCM_BUILD
      export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
      export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
      export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
      EOF
---
