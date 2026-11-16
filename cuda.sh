package: CUDA
version: "13.4.2_cudnn_9.26.1.1"
license: CUDA
build_requires:
  - alibuild-recipe-tools
env:
  CUDA_PATH: "$CUDA_ROOT"
track_env:
  ALIBUILD_O2_FORCE_GPU_TENSORRT: echo ${ALIBUILD_O2_FORCE_GPU_TENSORRT:-0}
---
#!/bin/bash -e
CUDA_VERSION="${PKGVERSION%%_cudnn_*}"
CUDNN_VERSION="${PKGVERSION#*_cudnn_}"
TENSORRT_VERSION="11.4.0.106"
TENSORRT_FILENAME=TensorRT-Enterprise-${TENSORRT_VERSION}-Linux-x86_64-cuda-${CUDA_VERSION%.*}-Release-external.tar.zst
if [[ ${ALIBUILD_O2_FORCE_GPU_TENSORRT} == 1 && ( -z $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES || ! -f "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${TENSORRT_FILENAME}" ) ]]; then
  echo "ERROR: ALIBUILD_O2_FORCE_GPU_TENSORRT=1 requires ${TENSORRT_FILENAME} in the folder given by ALIBUILD_O2_FORCE_GPU_BUILDSOURCES. For license reasons it must be downloaded manually from https://developer.nvidia.com/tensorrt/download/"
  exit 1
fi

fetch_source() # Usage: fetch_source <file> <url>; with ALIBUILD_O2_FORCE_GPU_BUILDSOURCES set, missing files are downloaded into that folder
{
  if [[ -n $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES ]]; then
    if [[ ! -f "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/$1" ]]; then
      curl -fL -o "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/$1.download" "$2"
      mv "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/$1.download" "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/$1"
    fi
    cp "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/$1" ./
  else
    curl -fL -o "$1" "$2"
  fi
}

FILENAME=cuda_${CUDA_VERSION}_linux.run
fetch_source "${FILENAME}" "https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${FILENAME}"

exclude_list=(
  "cuda-installer"
  "*-uninstaller"
  "NVIDIA-Linux-*.run"
  "builds/NVIDIA-Linux*"
  "builds/*.txt"
  "builds/*.json"
  "builds/cuda_documentation"
  "builds/cuda_gdb"
  "builds/cuda_sanitizer_api"
  "builds/integration"
  "builds/cuda_nsight"
  "builds/cuda_nvvp"
  "builds/nsight_compute"
  "builds/nsight_systems"
  "builds/nvidia_fs"
)

bash "${FILENAME}" --tar xf -X <(printf "%s\n" "${exclude_list[@]}")

merge_move()
{
  local src=$1
  local dst=$2

  mkdir -p "$dst"
  shopt -s dotglob nullglob

  local x
  for x in "$src"/*; do
    local name=${x##*/}
    local target="$dst/$name"

    if [[ ! -L "$x" && -d "$x" && -d "$target" ]]; then
      merge_move "$x" "$target"
      rmdir "$x"
    elif [[ -L "$x" && -L "$target" ]]; then
      rm -- "$x"
    else
      mv -- "$x" "$target"
    fi
  done
}

for i in builds/*/; do
  merge_move "$i" "$INSTALLROOT"
done

rm -Rf builds "${FILENAME}"

FILENAME=cudnn-linux-x86_64-${CUDNN_VERSION}_cuda13-archive.tar.xz
fetch_source "${FILENAME}" "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/${FILENAME}"
tar -Jxf "${FILENAME}"
mv cudnn-linux-x86_64-*/include/* "$INSTALLROOT"/include/
mv cudnn-linux-x86_64-*/lib/* "$INSTALLROOT"/lib64/
rm -Rf cudnn-linux-x86_64-*

if [[ ${ALIBUILD_O2_FORCE_GPU_TENSORRT} == 1 ]]; then
  tar --zstd -xf "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${TENSORRT_FILENAME}" --exclude="TensorRT-${TENSORRT_VERSION}/lib/*_win_*"
  merge_move TensorRT-${TENSORRT_VERSION}/include "$INSTALLROOT"/include
  merge_move TensorRT-${TENSORRT_VERSION}/lib "$INSTALLROOT"/lib64
  merge_move TensorRT-${TENSORRT_VERSION}/bin "$INSTALLROOT"/bin
  rm -Rf TensorRT-${TENSORRT_VERSION}
fi

ln -s lib64 "$INSTALLROOT"/lib

# Modulefile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv CUDA_PATH \$::env(BASEDIR)/$PKGNAME/\$version
EoF
