package: O2-RTC-test
version: "1.0"
requires:
  - O2
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
type $O2_ROOT/lib/libO2GPUTrackingOCL2.so

#o2-gpu-standalone-benchmark --noEvents -g --gpuType CUDA --RTCenable 1 --RTCcacheOutput 0 --RTCoptConstexpr 1 --RTCcompilePerKernel 1 --RTCrunTest 2
o2-gpu-standalone-benchmark --noEvents -g --gpuType HIP --RTCenable 1 --RTCcacheOutput 0 --RTCoptConstexpr 1 --RTCcompilePerKernel 1 --RTCrunTest 2

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
