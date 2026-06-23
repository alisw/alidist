package: O2-GPU-test
version: "1.0"
requires:
  - O2
  - gpu-system
license: GPL-3.0
force_rebuild: true
---
#!/bin/bash -e

if [[ -n ${GPU_SYSTEM_ROOT:-} && -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
  source $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh
fi

rm -Rf $BUILDDIR/gpu-test
mkdir $BUILDDIR/gpu-test
pushd $BUILDDIR/gpu-test

if [[ -n ${O2GPUCI_BACKENDS:-} ]]; then
  read -r -a GPU_BACKENDS <<< "${O2GPUCI_BACKENDS//,/ }"
else
  GPU_BACKENDS=()
  [[ ${O2_GPU_CUDA_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(CUDA)
  [[ ${O2_GPU_ROCM_AVAILABLE:-0} == 1 ]] && GPU_BACKENDS+=(HIP)
fi

if [[ ${#GPU_BACKENDS[@]} == 0 ]]; then
  echo "O2-GPU-test: no GPU backend selected or detected." >&2
  exit 1
fi

for BACKEND in "${GPU_BACKENDS[@]}"; do
  o2-gpu-standalone-benchmark --noEvents -g --gpuType "${BACKEND^^}"
done

popd
rm -Rf $BUILDDIR/gpu-test

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
cat > $INSTALLROOT/etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 O2/$O2_VERSION-$O2_REVISION
EoF
