package: ROCm
version: "10.1.0"
license: MIT
build_requires:
  - alibuild-recipe-tools
env:
  ROCM_PATH: "$ROCM_ROOT"
---
#!/bin/bash -e
ROCM_SUBVERSION=5
FULLVERSION=${PKGVERSION}
if [[ ! $FULLVERSION =~ \..*\. ]]; then FULLVERSION+=.0; fi

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

FILENAME=rocm-installer-${FULLVERSION}-${ROCM_SUBVERSION}.run
fetch_source "${FILENAME}" "https://stable.repo.amd.com/rocm/core/linux-installers/${FILENAME}"

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

bash ${FILENAME} rocm gfx=all compo=core-sdk nopostrocm verbose noexec noexec-cleanup || [[ -d rocm-installer ]]

for i in $(ls rocm-installer/component-rocm/ | grep '.xz$'); do
  mkdir unpack
  tar -C unpack -Jxf rocm-installer/component-rocm/"$i"
  for k in unpack/*; do
    pushd "$k"
    for j in *; do
      merge_move "$j"/*/*/ "$INSTALLROOT"
    done
    popd
  done
  rm -Rf unpack
done

rm -Rf "${FILENAME}" rocm-installer

FILENAME1="amdrocm10-migraphx-2.18.0-1.el8.x86_64.rpm"
FILENAME2="amdrocm10-migraphx-devel-2.18.0-1.el8.x86_64.rpm"
fetch_source "${FILENAME1}" "https://stable.repo.amd.com/rocm/migraphx/packages/rhel10/x86_64/${FILENAME1}"
fetch_source "${FILENAME2}" "https://stable.repo.amd.com/rocm/migraphx/packages/rhel10/x86_64/${FILENAME2}"

for i in "${FILENAME1}" "${FILENAME2}"; do rpm2cpio "$i" | cpio -idmv; done
merge_move ./opt/rocm/extras-${FULLVERSION%%.*}/ "$INSTALLROOT"
rm -Rf ./opt "${FILENAME1}" "${FILENAME2}"

rm -Rf "$INSTALLROOT"/bin/flatc "$INSTALLROOT"/bin/clinfo "$INSTALLROOT"/include/flatbuffers "$INSTALLROOT"/include/CL "$INSTALLROOT"/lib/libflatbuffers* "$INSTALLROOT"/lib/cmake/llvm "$INSTALLROOT"/lib/cmake/clang

# Modulefile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv ROCM_PATH \$::env(BASEDIR)/$PKGNAME/\$version
EoF
