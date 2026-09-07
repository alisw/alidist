package: CUDA
version: "13.3.1_cudnn_9.25.1.1"
license: CUDA
build_requires:
  - alibuild-recipe-tools
env:
  CUDA_PATH: "$CUDA_ROOT"
---
#!/bin/bash -e
DRIVER_VERSION=610.43.02
CUDA_VERSION="${PKGVERSION%%_cudnn_*}"
CUDNN_VERSION="${PKGVERSION#*_cudnn_}"
FILENAME=cuda_${CUDA_VERSION}_${DRIVER_VERSION}_linux.run
if [[ -n $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES ]]; then
  cp "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${FILENAME}" ./
else
  curl -o "${FILENAME}" "https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${FILENAME}"
fi

exclude_list=(
  "cuda-installer"
  "*-uninstaller"
  "NVIDIA-Linux-${narch}-${DRIVER_PV}.run"
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
if [[ -n $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES ]]; then
  cp "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${FILENAME}" ./
else
  curl -o "${FILENAME}" "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/${FILENAME}"
fi
tar -Jxf "${FILENAME}"
mv cudnn-linux-x86_64-*/include/* "$INSTALLROOT"/include/
mv cudnn-linux-x86_64-*/lib/* "$INSTALLROOT"/lib64/
rm -Rf cudnn-linux-x86_64-*

ln -s lib64 "$INSTALLROOT"/lib

# Modulefile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv CUDA_PATH \$::env(BASEDIR)/$PKGNAME/\$version
EoF
