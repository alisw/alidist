package: O2Suite
version: "1.0.0"
tag: "O2Suite-1.0.0"
requires:
  - Common-O2
  - Control
  - Monitoring
  - Configuration
  - O2
  - "GCC-Toolchain:(?!osx)"
  - InfoLogger
  - ReadoutCard
  - Readout
  - qcg
  - QualityControl
  - "DataDistribution:(?!osx)"
  - "ALF:(?!osx|slc8)"
  - "TpcFecUtils:(?!osx)"
valid_defaults:
  - o2
  - o2-dataflow
  - o2-dev-fairroot
  - alo
  - o2-prod
  - o2-ninja
---
#!/bin/bash -ex

MODULEFILE_DEPS=
for RPKG in $REQUIRES; do
  [[ $RPKG != defaults* ]] || continue
  RPKG_UP=$(echo $RPKG|tr '[:lower:]' '[:upper:]'|tr '-' '_')
  RPKG_VERSION=$(eval echo "\$${RPKG_UP}_VERSION")
  RPKG_REVISION=$(eval echo "\$${RPKG_UP}_REVISION")
  MODULEFILE_DEPS="${MODULEFILE_DEPS} ${RPKG}/${RPKG_VERSION}-${RPKG_REVISION}"
done
MODULEFILE_DEPS=$(echo $MODULEFILE_DEPS)

# Modulefile
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
module load BASE/1.0 ${MODULEFILE_DEPS}
EoF
