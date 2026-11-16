package: O2-RTC-test
version: "1.0"
requires:
  - O2
license: GPL-3.0
force_rebuild: true
---
#!/bin/bash -e

if [[ "$G4INSTALL" != "" ]]; then
  `$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`
fi

rm -Rf $BUILDDIR/rtc-test
mkdir $BUILDDIR/rtc-test
pushd $BUILDDIR/rtc-test

type $O2_ROOT/lib/libO2GPUTrackingCUDA.so
type $O2_ROOT/lib/libO2GPUTrackingHIP.so
type $O2_ROOT/lib/libO2GPUTrackingOCL.so

# libO2GPUTrackingCUDA.so links libcuda.so.1 (driver). Without a driver / nvidia-container-runtime, the file is missing. We use the stub from the nvidia-cuda-toolkit. Need to link the *.1 version of the file, sicen only libcuda.so (link-time name) is shipped
if ! ldconfig -p | grep -q 'libcuda\.so\.1 '; then
  if [[ -f $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh ]]; then
    source $GPU_SYSTEM_ROOT/etc/gpu-features-available.sh
  fi
  if [[ -n $O2_GPU_CUDA_HOME && -f ${O2_GPU_CUDA_HOME}/targets/x86_64-linux/lib/stubs/libcuda.so ]]; then
    mkdir -p cuda-stub
    ln -sf ${O2_GPU_CUDA_HOME}/targets/x86_64-linux/lib/stubs/libcuda.so cuda-stub/libcuda.so.1
    export LD_LIBRARY_PATH+=:$PWD/cuda-stub:${O2_GPU_CUDA_HOME}/targets/x86_64-linux/lib/stubs/
  else # fallback to old version if no stub in ${O2_GPU_CUDA_HOME}
    LD_LIBRARY_PATH+=$(find /usr/local/cuda* -type d -name stubs -prune -false -o \( -type f -o -type l \) -name libcuda.so -printf ':%h' -quit)
  fi
fi

o2-gpu-standalone-benchmark --noEvents -g --gpuType CUDA --RTCenable 1 --RTCcacheOutput 0 --RTCoptConstexpr 1 --RTCcompilePerKernel 1 --RTCTECHrunTest 2
o2-gpu-standalone-benchmark --noEvents -g --gpuType HIP --RTCenable 1 --RTCcacheOutput 0 --RTCoptConstexpr 1 --RTCcompilePerKernel 1 --RTCTECHrunTest 2

popd
rm -Rf $BUILDDIR/rtc-test

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
