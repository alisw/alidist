package: gpu-system
version: "error-notset"
allow_system_package_upload: true
build_requires:
  - alibuild-recipe-tools
prefer_system: .*
prefer_system_check: |
  #!/bin/bash -e
  rm -Rf alibuild-gpu-system-temp-dir
  mkdir alibuild-gpu-system-temp-dir
  pushd alibuild-gpu-system-temp-dir > /dev/null
  GPU_FEATURES=
  GPU_SETTINGS=
  add_feature() {
    [[ $GPU_FEATURES && $GPU_FEATURES != *"$1" ]] && GPU_FEATURES+="$1"
    GPU_FEATURES+="$2"
  }
  add_setting() {
    GPU_SETTINGS+="$1"$'\n'
  }
  verge() { [[ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]; }

  while true; do
    # Valid options:
    # - auto: normal auto-detection, fail if CMake is missing
    # - onthefly: auto-detection at runtime, no CUDNN / MIOPEN
    # - fullauto: if system CMake is found behave as auto, otherwise as onthefly (default)
    # - 1 / force: detect forcing all backends, and fail if a feature is not found
    # - ci: for now defaults to 1
    # - disable: disable all backends
    # - manual: disable auto-detection, set features manually
    # - build: build GPU tools from alidist recipe
    # 0 / unset: defaults to fullauto

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "disable" ]]; then
      GPU_FEATURES=disabled
      break
    fi

    if [[ -z ${ALIBUILD_O2_FORCE_GPU} || ${ALIBUILD_O2_FORCE_GPU} == "0" ]]; then
      ALIBUILD_O2_FORCE_GPU=fullauto
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "force" || ${ALIBUILD_O2_FORCE_GPU} == "ci" ]]; then
      ALIBUILD_O2_FORCE_GPU=1
    fi

    if [[ -z $ALIBUILD_VERSION ]] || ! verge 1.17.44 $ALIBUILD_VERSION; then
      if [[ $ALIBUILD_O2_FORCE_GPU != "onthefly" || $ALIBUILD_O2_FORCE_GPU != "fullauto" ]]; then
        GPU_FEATURES="error-aliBuild too old for gpu-system"
      else
        GPU_FEATURES=disabled-old-aliBuild
      fi
      break
    fi

    if [[ ${ALIBUILD_O2_FORCE_GPU} == "build" ]]; then
      GPU_FEATURES=build-from-alidist
      if [[ ${ALIBUILD_O2_FORCE_GPU_CUDA:-1} != "0" ]]; then
        echo "alibuild_system_replace_requires: CUDA"
        add_setting 'if [[ -z ${CUDA_PATH} ]]; then echo "ERROR: CUDA PATH NOT SET!"; exit 1; fi'
        add_setting "export O2_GPU_CUDA_AVAILABLE=1"
        add_setting "export O2_GPU_CUDNN_AVAILABLE=1"
        add_setting 'export O2_GPU_CUDA_HOME="${CUDA_PATH}"'
        CUDA_DEFAULT_ARCH=$(grep -m1 -oP 'set\(CUDA_COMPUTETARGET_DEFAULT_FULL\s+\K[^)]+' ${ALIBUILD_CONFIG_DIR}/resources/FindO2GPU.cmake)
        add_feature - cuda_arch_$(sed -e "s/;\|-/_/g" <<< "${ALIBUILD_O2_FORCE_GPU_CUDA_ARCH:-${CUDA_DEFAULT_ARCH}}")
        add_setting 'export O2_GPU_CUDA_AVAILABLE_ARCH="'${ALIBUILD_O2_FORCE_GPU_CUDA_ARCH:-${CUDA_DEFAULT_ARCH}}'"'
      fi
      if [[ ${ALIBUILD_O2_FORCE_GPU_HIP:-1} != "0" ]]; then
        echo "alibuild_system_replace_requires: ROCm"
        add_setting 'if [[ -z ${ROCM_PATH} ]]; then echo "ERROR: ROCm PATH NOT SET!"; exit 1; fi'
        add_setting "export O2_GPU_ROCM_AVAILABLE=1"
        add_setting "export O2_GPU_MIOPEN_AVAILABLE=1"
        add_setting "export O2_GPU_MIGRAPHX_AVAILABLE=1"
        add_setting 'export O2_GPU_ROCM_HOME="${ROCM_PATH}"'
        ROCM_DEFAULT_ARCH=$(grep -m1 -oP 'set\(HIP_AMDGPUTARGET_DEFAULT_FULL\s+\K[^)]+' ${ALIBUILD_CONFIG_DIR}/resources/FindO2GPU.cmake)
        add_feature - rocm_arch_$(sed -e "s/;\|-/_/g" <<< "${ALIBUILD_O2_FORCE_GPU_HIP_ARCH:-${ROCM_DEFAULT_ARCH}}")
        add_setting 'export O2_GPU_ROCM_AVAILABLE_ARCH="'${ALIBUILD_O2_FORCE_GPU_HIP_ARCH:-${ROCM_DEFAULT_ARCH}}'"'
      fi
      break
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
        case $(uname) in
          Darwin*) add_feature - metal;;
        esac

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
        elif [[ ${ALIBUILD_O2_FORCE_GPU} != "fullauto" ]]; then
          GPU_FEATURES="error-ALIBUILD_O2_FORCE_GPU != fullauto, but running CMake for GPU detection failed"
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
      add_feature - auto
    else
      [[ $GPU_CUDA_ENABLED != 1 ]] && GPU_CUDA_ENABLED=0
      [[ $GPU_HIP_ENABLED != 1 ]] && GPU_HIP_ENABLED=0
      [[ $GPU_OPENC_ENABLED != 1 ]] && GPU_OPENC_ENABLED=0
    fi

    [[ -n ${ALIBUILD_O2_FORCE_GPU_CUDA} ]] && GPU_CUDA_ENABLED=${ALIBUILD_O2_FORCE_GPU_CUDA}
    [[ -n ${ALIBUILD_O2_FORCE_GPU_HIP} ]] && GPU_HIP_ENABLED=${ALIBUILD_O2_FORCE_GPU_HIP}
    [[ -n ${ALIBUILD_O2_FORCE_GPU_OPENCL} ]] && GPU_OPENCL_ENABLED=${ALIBUILD_O2_FORCE_GPU_OPENCL}

    if [[ $GPU_CUDA_ENABLED == 1 ]]; then
      add_feature - cuda
      add_setting "export O2_GPU_CUDA_AVAILABLE=1"
      [[ -n $GPU_CUDA_VERSION ]] && add_feature _ ${GPU_CUDA_VERSION//-/_}
      if [[ -n $GPU_CUDA_ARCHITECTURE ]]; then
        add_feature _ arch_$(sed -e "s/;\|-/_/g" <<< "${GPU_CUDA_ARCHITECTURE}")
        add_setting 'export O2_GPU_CUDA_AVAILABLE_ARCH="'${GPU_CUDA_ARCHITECTURE}'"'
      fi
      [[ -n $O2_GPU_CUDA_HOME ]] && add_setting 'export O2_GPU_CUDA_HOME="'${O2_GPU_CUDA_HOME}'"'
    elif [[ $GPU_CUDA_ENABLED == "AUTO" ]]; then
      add_setting "export O2_GPU_CUDA_AVAILABLE=AUTO"
    fi

    if [[ $GPU_HIP_ENABLED == 1 ]]; then
      add_feature - rocm
      add_setting "export O2_GPU_ROCM_AVAILABLE=1"
      [[ -n $GPU_HIP_VERSION ]] && add_feature _ ${GPU_HIP_VERSION//-/_}
      if [[ -n $GPU_HIP_ARCHITECTURE ]]; then
        add_feature _ arch_$(sed -e "s/;\|-/_/g" <<< "${GPU_HIP_ARCHITECTURE}")
        add_setting 'export O2_GPU_ROCM_AVAILABLE_ARCH="'${GPU_HIP_ARCHITECTURE}'"'
      fi
      [[ -n $O2_GPU_ROCM_HOME ]] && add_setting 'export O2_GPU_ROCM_HOME="'${O2_GPU_ROCM_HOME}'"'
    elif [[ $GPU_HIP_ENABLED == "AUTO" ]]; then
      add_setting "export O2_GPU_ROCM_AVAILABLE=AUTO"
    fi


    if [[ $GPU_OPENCL_ENABLED == 1 ]]; then
      add_feature - opencl
      add_setting "export O2_GPU_OPENCL_AVAILABLE=1"
    elif [[ $GPU_OPENCL_ENABLED == "AUTO" ]]; then
      add_setting "export O2_GPU_OPENCL_AVAILABLE=AUTO"
    fi

    # Detect MIOpen requirements, eventually should improve this to be based on CMake as well
    if [[ ${ALIBUILD_O2_FORCE_GPU_MIOPEN} == 1 ]] || [[ ${GPU_FEATURES} =~ (^|-)"rocm"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_MIOPEN} != 0 && \
      -d /opt/rocm/lib/cmake && \
      -d /opt/rocm/lib/hipblaslt && \
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
      -d /opt/rocm/include/rccl ]]; then
        add_feature - miopen
        add_setting "export O2_GPU_MIOPEN_AVAILABLE=1"
    fi

    MIGRAPHX_C_API=
    for _hdr in /opt/rocm/lib/migraphx/include/migraphx/migraphx.h /opt/rocm/include/migraphx/migraphx.h; do
      if [[ -f $_hdr ]] && grep -q fp4x2 "$_hdr"; then MIGRAPHX_C_API=$_hdr; break; fi
    done
    if [[ $ALIBUILD_O2_FORCE_GPU_MIGRAPHX == 1 ]] || [[ $GPU_FEATURES =~ (^|-)"miopen"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_MIGRAPHX} != 0 && -n $MIGRAPHX_C_API ]]; then
      add_feature - migraphx
      add_setting "export O2_GPU_MIGRAPHX_AVAILABLE=1"
    fi

    if [[ $ALIBUILD_O2_FORCE_GPU_CUDNN == 1 ]] || [[ $GPU_FEATURES =~ (^|-)"cuda"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_CUDNN} != 0 && ( -f /usr/include/cudnn.h || -f /opt/cuda/targets/x86_64-linux/include/cudnn.h ) ]]; then
      add_feature - cudnn
      add_setting "export O2_GPU_CUDNN_AVAILABLE=1"
    fi

    if [[ $ALIBUILD_O2_FORCE_GPU_TENSORRT == 1 ]] || [[ $GPU_FEATURES =~ (^|-)"cudnn"(-|_|$) && ${ALIBUILD_O2_FORCE_GPU_TENSORRT} != 0 && $(find /usr/lib* /opt/cuda /usr/local/cuda -name "libnvinfer*" -print -quit | wc -l 2>&1) != 0 ]]; then
      add_feature - tensorrt
      add_setting "export O2_GPU_TENSORRT_AVAILABLE=1"
    fi

    if [[ $ALIBUILD_O2_FORCE_GPU == "1" && -n $_ml_missing ]]; then
      for _ml in miopen cudnn; do
        if [[ $GPU_FEATURES =~ (^|-)"$_ml"(-|_|$) ]]; then
          GPU_FEATURES="error-ALIBUILD_O2_FORCE_GPU=1 set, but not all ML libraries detected: $_ml"
          break
        fi
      done
    fi

    [[ -z $GPU_FEATURES ]] && GPU_FEATURES=none
    break
  done

  popd > /dev/null
  rm -Rf alibuild-gpu-system-temp-dir

  echo "alibuild_system_replace: $GPU_FEATURES"
  echo "alibuild_system_replace_track_env: ALIBUILD_O2_GPU_SETTINGS="$(base32 -i -w0 <<< "${GPU_SETTINGS}")
  true

prefer_system_replacement_specs:
  "error.*":
    version: error
    recipe: |
      #!/bin/bash -e
      #%Module1.0
      echo "ERROR: gpu-system.sh GPU detection failed: ${ALIBUILD_PREFER_SYSTEM_KEY}" | sed "s/error-//" 1>&2
      exit 1
  ".*":
    version: "%(key)s"
    build_requires:
      - alibuild-recipe-tools
    recipe: |
      #!/bin/bash -e
      mkdir -p "$INSTALLROOT/etc/modulefiles"
      echo "gpu-system key: $PKG_VERSION"
      alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
      {
        GPU_SETTINGS=$(base32 -d 2> /dev/null <<< ${ALIBUILD_O2_GPU_SETTINGS})
        for i in O2_GPU_CUDA_AVAILABLE O2_GPU_ROCM_AVAILABLE O2_GPU_OPENCL_AVAILABLE O2_GPU_MIOPEN_AVAILABLE O2_GPU_CUDNN_AVAILABLE O2_GPU_MIGRAPHX_AVAILABLE O2_GPU_TENSORRT_AVAILABLE; do
          if [[ ! "${GPU_SETTINGS}" =~ $i ]]; then
            echo "export $i=0"
          fi
        done
        echo "${GPU_SETTINGS}"
      } > "$INSTALLROOT"/etc/gpu-features-available.sh
---
