package: ROCm
version: "10.0.0"
license: MIT
build_requires:
  - alibuild-recipe-tools
env:
  ROCM_PATH: "$ROCM_ROOT"
---
#!/bin/bash -e
ROCM_SUBVERSION=4
FULLVERSION=${PKGVERSION}
if [[ ! $FULLVERSION =~ \..*\. ]]; then FULLVERSION+=.0; fi

FILENAME=rocm-installer-${FULLVERSION}-${ROCM_SUBVERSION}.run
if [[ -n $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES ]]; then
  cp "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${FILENAME}" ./
else
  curl -o "${FILENAME}" "https://repo.radeon.com/rocm/installer/rocm-runfile-installer/rocm-rel-${PKGVERSION}/${FILENAME}"
fi

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
  tar -C unpack -Jxf rocm-installer/component-rocm/$i
  for k in unpack/*; do
    pushd $k
    for j in *; do
      merge_move $j/*/*/ $INSTALLROOT
    done
    popd
  done
  rm -Rf unpack
done

rm -Rf "$INSTALLROOT"/bin/flatc "$INSTALLROOT"/bin/clinfo "$INSTALLROOT"/include/flatbuffers "$INSTALLROOT"/include/CL "$INSTALLROOT"/lib/libflatbuffers*

# Modulefile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv ROCM_PATH \$::env(BASEDIR)/$PKGNAME/\$version
EoF
