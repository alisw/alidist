package: gpu-system
version: "error"
allow_system_package_upload: true
prefer_system: .*
prefer_system_check: |
  #!/bin/bash -e
  rm -Rf alibuild-gpu-system-temp-dir
  mkdir alibuild-gpu-system-temp-dir
  pushd alibuild-gpu-system-temp-dir > /dev/null
  GPU_FEATURES=

  while true; do
    if [[ ${ALIBUILD_O2_FORCE_GPU} == "disable" ]]; then
      GPU_FEATURES=none
      break
    fi
    case $(uname) in
      Darwin*) GPU_FEATURES+=${GPU_FEATURES:+-}metal;;
    esac

    # Valid options:
    # - auto: normal auto-detection, fail if CMake is missing
    # - onthefly: auto-detection at runtime, no CUDNN / MIOPEN
    # - fullauto: if system CMake is found behave as auto, otherwise as onthefly
    # - 1 / force: detect forcing all backends, and fail if a feature is not found
    # - ci: for now defaults to 1
    # - disable: disable all backends
    # - manual: disable auto-detection, set features manually
    # 0 / unset: defaults to fullauto

    if [[ -z ${ALIBUILD_O2_FORCE_GPU} || ${ALIBUILD_O2_FORCE_GPU} == "0" ]]; then
      ALIBUILD_O2_FORCE_GPU=fullauto
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "force" || ${ALIBUILD_O2_FORCE_GPU} == "ci" ]]; then
      ALIBUILD_O2_FORCE_GPU=1
    fi
    if [[ ${ALIBUILD_O2_FORCE_GPU} == "1" ]]; then
      [[ -z $ALIBUILD_O2_FORCE_GPU_CUDA_ARCH ]] && ALIBUILD_O2_FORCE_GPU_CUDA_ARCH=default
      [[ -z $ALIBUILD_O2_FORCE_GPU_HIP_ARCH ]] && ALIBUILD_O2_FORCE_GPU_HIP_ARCH=default
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} != "manual" && ${ALIBUILD_O2_FORCE_GPU} != "onthefly" ]]; then

      if ! type cmake; then
        if [[ ${ALIBUILD_O2_FORCE_GPU} != "fullauto" ]]; then
          GPU_FEATURES="error-No system CMake found for gpu-system.sh"
          break
        else
          ALIBUILD_O2_FORCE_GPU="onthefly" # divert to onthefly since no system CMake found
        fi
      else
        current_version=$(cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3)
        verge() { [[  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]; }
        if ! verge 3.26.0 $current_version; then
          if [[ ${ALIBUILD_O2_FORCE_GPU} != "fullauto" ]]; then
            GPU_FEATURES="error-Too old system CMake for gpu-system.sh"
            break
          else
            ALIBUILD_O2_FORCE_GPU="onthefly" # divert to onthefly since no system CMake found
          fi
        fi
      fi

      if [[ ${ALIBUILD_O2_FORCE_GPU} != "onthefly" ]]; then
        cat > CMakeLists.txt << "EOF"
        cmake_minimum_required(VERSION 3.26 FATAL_ERROR)
        project(gpu-system)
        list(APPEND CMAKE_MODULE_PATH "$ENV{ALIBUILD_CONFIG_DIR}/resources/")
        include(FeatureSummary)
        set(GPUCA_FINDO2GPU_CHECK_ONLY 1)
        set(OPENCL_COMPATIBLE_CLANG_FOUND 1)
        find_package(O2GPU REQUIRED)
        if(CUDA_ENABLED)
          set(CUDA_ENABLED 1)
        endif()
        if(HIP_ENABLED)
          set(HIP_ENABLED 1)
        endif()
        if(OPENCL_ENABLED)
          set(OPENCL_ENABLED 1)
        endif()
        list(REMOVE_DUPLICATES CMAKE_CUDA_ARCHITECTURES)
        list(REMOVE_DUPLICATES CMAKE_HIP_ARCHITECTURES)

        # Derive toolkit roots from compiler locations (best-effort)
        set(GPU_CUDA_HOME "")
        if(CUDA_ENABLED AND DEFINED CMAKE_CUDA_COMPILER AND EXISTS "${CMAKE_CUDA_COMPILER}")
          get_filename_component(_cuda_bin_dir "${CMAKE_CUDA_COMPILER}" DIRECTORY)
          get_filename_component(GPU_CUDA_HOME "${_cuda_bin_dir}" DIRECTORY)
        endif()

        set(GPU_ROCM_HOME "")
        if(HIP_ENABLED AND DEFINED CMAKE_HIP_COMPILER AND EXISTS "${CMAKE_HIP_COMPILER}")
          # hipcc is typically in <ROCM>/llvm/bin/hipcc
          get_filename_component(_hip_bin_dir "${CMAKE_HIP_COMPILER}" DIRECTORY)
          get_filename_component(_hip_llvm_dir "${_hip_bin_dir}" DIRECTORY)
          get_filename_component(GPU_ROCM_HOME "${_hip_llvm_dir}" DIRECTORY)
        endif()

        file(CONFIGURE
            OUTPUT "env.sh"
            CONTENT "
              export GPU_CUDA_ENABLED=\"@CUDA_ENABLED@\"
              export GPU_HIP_ENABLED=\"@HIP_ENABLED@\"
              export GPU_OPENCL_ENABLED=\"@OPENCL_ENABLED@\"
              export GPU_CUDA_VERSION=\"@CMAKE_CUDA_COMPILER_VERSION@\"
              export GPU_HIP_VERSION=\"@hip_VERSION@\"
              export GPU_CUDA_ARCHITECTURE=\"@CMAKE_CUDA_ARCHITECTURES@\"
              export GPU_HIP_ARCHITECTURE=\"@CMAKE_HIP_ARCHITECTURES@\"
              export O2_GPU_CUDA_HOME=\"@GPU_CUDA_HOME@\"
              export O2_GPU_ROCM_HOME=\"@GPU_ROCM_HOME@\"
            ")
  EOF

        # Run System CMake, trying to detect as many GPU features as possible
        cmake -Wno-dev . \
          ${ALIBUILD_O2_FORCE_GPU_HIP_ARCH:+-DHIP_AMDGPUTARGET=${ALIBUILD_O2_FORCE_GPU_HIP_ARCH}} \
          ${ALIBUILD_O2_FORCE_GPU_CUDA_ARCH:+-DCUDA_COMPUTETARGET=${ALIBUILD_O2_FORCE_GPU_CUDA_ARCH}} \
          &> /dev/null
        if [[ $? -eq 0 && -f env.sh ]]; then
          source env.sh

          CUDA_HOME_ENC=""
          ROCM_HOME_ENC=""

          if [[ -n "${O2_GPU_CUDA_HOME}" ]]; then
            CUDA_HOME_ENC="$(printf '%s' "${O2_GPU_CUDA_HOME}" | base32 2>/dev/null | tr -d '\n' | tr '=' '_')"
          fi
          if [[ -n "${O2_GPU_ROCM_HOME}" ]]; then
            ROCM_HOME_ENC="$(printf '%s' "${O2_GPU_ROCM_HOME}" | base32 2>/dev/null | tr -d '\n' | tr '=' '_')"
          fi

        elif [[ ${ALIBUILD_O2_FORCE_GPU} != "fullauto" ]]; then
          GPU_FEATURES="error-ALIBUILD_O2_FORCE_GPU=1 set, but running CMake for GPU detection failed"
          break
        else
          ALIBUILD_O2_FORCE_GPU="onthefly"
        fi
      fi
    else
      [[ -n $ALIBUILD_O2_FORCE_GPU_CUDA_ARCH ]] && GPU_CUDA_ARCHITECTURE="${ALIBUILD_O2_FORCE_GPU_CUDA_ARCH}"
      [[ -n $ALIBUILD_O2_FORCE_GPU_HIP_ARCH ]] && GPU_HIP_ARCHITECTURE="${ALIBUILD_O2_FORCE_GPU_HIP_ARCH}"
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "1" ]] && [[ $GPU_HIP_ENABLED != 1 || $GPU_CUDA_ENABLED != 1 || $GPU_OPENCL_ENABLED != 1 ]]; then
      GPU_FEATURES="error-ALIBUILD_O2_FORCE_GPU=1 set, but not all GPU backends detected"
      break
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "manual" ]]; then
      GPU_CUDA_ENABLED=0
      GPU_HIP_ENABLED=0
      GPU_OPENCL_ENABLED=0
    elif [[ ${ALIBUILD_O2_FORCE_GPU} == "onthefly" ]]; then
      GPU_CUDA_ENABLED=AUTO
      GPU_HIP_ENABLED=AUTO
      GPU_OPENCL_ENABLED=AUTO
      GPU_FEATURES+=${GPU_FEATURES:+-}auto
    else
      [[ $GPU_CUDA_ENABLED != 1 ]] && GPU_CUDA_ENABLED=0
      [[ $GPU_HIP_ENABLED != 1 ]] && GPU_HIP_ENABLED=0
      [[ $GPU_OPENC_ENABLED != 1 ]] && GPU_OPENC_ENABLED=0
    fi

    if [[ -n ${ALIBUILD_O2_FORCE_GPU_CUDA} ]]; then
      GPU_CUDA_ENABLED=${ALIBUILD_O2_FORCE_GPU_CUDA}
    fi
    if [[ -n ${ALIBUILD_O2_FORCE_GPU_HIP} ]]; then
      GPU_HIP_ENABLED=${ALIBUILD_O2_FORCE_GPU_HIP}
    fi
    if [[ -n ${ALIBUILD_O2_FORCE_GPU_OPENCL} ]]; then
      GPU_OPENCL_ENABLED=${ALIBUILD_O2_FORCE_GPU_OPENCL}
    fi

    if [[ $GPU_CUDA_ENABLED == 1 ]]; then
      GPU_FEATURES+=${GPU_FEATURES:+-}cuda
      if [[ -n ${GPU_CUDA_ARCHITECTURE} ]]; then
        GPU_FEATURES+=_arch@${GPU_CUDA_ARCHITECTURE//;/#}@
      fi
      if [[ -n ${GPU_CUDA_VERSION} ]]; then
        GPU_FEATURES+=_${GPU_CUDA_VERSION}
      fi
    fi

    if [[ $GPU_HIP_ENABLED == 1 ]]; then
      GPU_FEATURES+=${GPU_FEATURES:+-}rocm
      if [[ -n ${GPU_HIP_ARCHITECTURE} ]]; then
        GPU_FEATURES+=_arch@${GPU_HIP_ARCHITECTURE//;/#}@
      fi
      if [[ -n ${GPU_HIP_VERSION} ]]; then
        GPU_FEATURES+=_${GPU_HIP_VERSION}
      fi
    fi

    if [[ $GPU_OPENCL_ENABLED == 1 ]]; then
      GPU_FEATURES+=${GPU_FEATURES:+-}opencl
    fi

    # Detect MI GPU features
    # Eventually should improve this to be based on CMake as well

    if [[ ${ALIBUILD_O2_FORCE_GPU_MIOPEN} == 1 ]] || [[ ${GPU_FEATURES} =~ (^|-)"rocm"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_MIOPEN} != 0 && \
      -d /opt/rocm/lib/cmake && \
      -d /opt/rocm/include/hip && \
      -d /opt/rocm/include/rocprim && \
      -d /opt/rocm/include/thrust && \
      -d /opt/rocm/include/hipcub && \
      -d /opt/rocm/include/hiprand && \
      -d /opt/rocm/include/hipblas && \
      -d /opt/rocm/include/hipsparse && \
      -d /opt/rocm/include/hipfft && \
      -d /opt/rocm/include/rocblas && \
      -d /opt/rocm/include/rocrand && \
      -d /opt/rocm/include/miopen && \
      -d /opt/rocm/include/rccl && \
      -d /opt/rocm/lib/hipblaslt ]]; then
        GPU_FEATURES+=${GPU_FEATURES:+-}miopen
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU_MIGRAPHX} == 1 ]] || [[ ${GPU_FEATURES} =~ (^|-)"miopen"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_MIGRAPHX} != 0 && -d /opt/rocm/lib/migraphx ]]; then
        GPU_FEATURES+=${GPU_FEATURES:+-}migraphx
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU_CUDNN} == 1 ]] || [[ ${GPU_FEATURES} =~ (^|-)"cuda"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_CUDNN} != 0 && ( -f /usr/include/cudnn.h || -f /opt/cuda/targets/x86_64-linux/include/cudnn.h ) ]]; then
        GPU_FEATURES+=${GPU_FEATURES:+-}cudnn
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU_TENSORRT} == 1 ]] || [[ ${GPU_FEATURES} =~ (^|-)"cudnn"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_TENSORRT} != 0 && $(find /usr/lib* /opt/cuda /usr/local/cuda -name "libnvinfer*" -print -quit | wc -l 2>&1) != 0 ]]; then
        GPU_FEATURES+=${GPU_FEATURES:+-}tensorrt
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "1" ]] && ! [[ ${GPU_FEATURES} =~ (^|-)"miopen"(-|_|$) && ${GPU_FEATURES} =~ (^|-)"migraphx"(-|_|$) && ${GPU_FEATURES} =~ (^|-)"cudnn"(-|_|$) && ${GPU_FEATURES} =~ (^|-)"tensorrt"(-|_|$) ]]; then
      GPU_FEATURES="error-ALIBUILD_O2_FORCE_GPU=1 set, but not all ML libraries detected"
      break
    fi

    # Append encoded toolkit roots to the version key
    if [[ "${GPU_CUDA_ENABLED}" == "1" && -n "${CUDA_HOME_ENC}" ]]; then
      GPU_FEATURES+=${GPU_FEATURES:+-}cuda_home@${CUDA_HOME_ENC}@
    fi
    if [[ "${GPU_HIP_ENABLED}" == "1" && -n "${ROCM_HOME_ENC}" ]]; then
      GPU_FEATURES+=${GPU_FEATURES:+-}rocm_home@${ROCM_HOME_ENC}@
    fi

    if [[ -z ${GPU_FEATURES} ]]; then
      GPU_FEATURES=none
    fi
    break
  done

  popd > /dev/null
  rm -Rf alibuild-gpu-system-temp-dir

  echo "alibuild_system_replace: ${GPU_FEATURES}"
  true

prefer_system_replacement_specs:
  "error.*":
    version: error
    recipe: |
      #!/bin/bash -e
      #%Module1.0
      echo "ERROR: gpu-system.sh GPU detection failed: ${ALIBUILD_PREFER_SYSTEM_KEY}" 1>&2
      exit 1
  ".*":
    version: "%(key)s"
    recipe: |
      #!/bin/bash -e
      #%Module1.0
      mkdir -p "$INSTALLROOT"/etc
      rm -f "$INSTALLROOT"/etc/gpu-features-available.sh
      {
        # Availability flags
        O2_GPU_CUDA_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)cuda(-|_|$) ]] && echo 1 ) || ( [[ "${PKG_VERSION}" =~ (^|-)auto(-|_|$) ]] && echo auto || echo 0 ) )"
        O2_GPU_ROCM_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)rocm(-|_|$) ]] && echo 1 ) || ( [[ "${PKG_VERSION}" =~ (^|-)auto(-|_|$) ]] && echo auto || echo 0 ) )"
        O2_GPU_OPENCL_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)opencl(-|_|$) ]] && echo 1 ) || ( [[ "${PKG_VERSION}" =~ (^|-)auto(-|_|$) ]] && echo auto || echo 0 ) )"
        O2_GPU_MIOPEN_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)miopen(-|_|$) ]] && echo 1 ) || echo 0 )"
        O2_GPU_CUDNN_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)cudnn(-|_|$) ]] && echo 1 ) || echo 0 )"
        O2_GPU_MIGRAPHX_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)migraphx(-|_|$) ]] && echo 1 ) || echo 0 )"
        O2_GPU_TENSORRT_AVAILABLE="$( ( [[ "${PKG_VERSION}" =~ (^|-)tensorrt(-|_|$) ]] && echo 1 ) || echo 0 )"

        echo "export O2_GPU_ROCM_AVAILABLE=\"${O2_GPU_ROCM_AVAILABLE}\""
        echo "export O2_GPU_CUDA_AVAILABLE=\"${O2_GPU_CUDA_AVAILABLE}\""
        echo "export O2_GPU_OPENCL_AVAILABLE=\"${O2_GPU_OPENCL_AVAILABLE}\""
        echo "export O2_GPU_MIOPEN_AVAILABLE=\"${O2_GPU_MIOPEN_AVAILABLE}\""
        echo "export O2_GPU_CUDNN_AVAILABLE=\"${O2_GPU_CUDNN_AVAILABLE}\""
        echo "export O2_GPU_MIGRAPHX_AVAILABLE=\"${O2_GPU_MIGRAPHX_AVAILABLE}\""
        echo "export O2_GPU_TENSORRT_AVAILABLE=\"${O2_GPU_TENSORRT_AVAILABLE}\""

        ### CUDA
        O2_GPU_CUDA_HOME=""

        if [[ "${O2_GPU_CUDA_AVAILABLE}" == "1" && "${PKG_VERSION}" =~ cuda_home@([^@]*)@ ]]; then
          echo "export O2_GPU_CUDA_HOME=\"$(printf '%s' "${BASH_REMATCH[1]}" | tr '_' '=' | base32 -d 2>/dev/null)\""
        else
          echo "export O2_GPU_CUDA_HOME="
        fi

        if [[ "${O2_GPU_CUDA_AVAILABLE}" == "1" ]] && [[ "${PKG_VERSION}" =~ (^|-)cuda_arch@ ]]; then
          echo "${PKG_VERSION}" | grep -E -o '(^|-)cuda_arch@[^@]*@' | sed -e 's/-*cuda_arch/export O2_GPU_CUDA_AVAILABLE_ARCH=/' -e 's/@/"/g' -e 's/#/;/g'
        fi

        ### ROCm
        O2_GPU_ROCM_HOME=""

        if [[ "${O2_GPU_ROCM_AVAILABLE}" == "1" && "${PKG_VERSION}" =~ rocm_home@([^@]*)@ ]]; then
          echo "export O2_GPU_ROCM_HOME=\"$(printf '%s' "${BASH_REMATCH[1]}" | tr '_' '=' | base32 -d 2>/dev/null)\""
        else
          echo "export O2_GPU_ROCM_HOME="
        fi

        if [[ "${O2_GPU_ROCM_AVAILABLE}" == "1" ]] && [[ "${PKG_VERSION}" =~ (^|-)rocm_arch@ ]]; then
          echo "${PKG_VERSION}" | grep -E -o '(^|-)rocm_arch@[^@]*@' | sed -e 's/-*rocm_arch/export O2_GPU_ROCM_AVAILABLE_ARCH=/' -e 's/@/"/g' -e 's/#/;/g'
        fi
      } > "$INSTALLROOT"/etc/gpu-features-available.sh
---
