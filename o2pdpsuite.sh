package: O2PDPSuite
version: "%(tag_basename)s"
tag: "epn-20220704"
requires:
  - O2
  - DataDistribution
  - QualityControl
  - O2DPG
  - O2sim
  - ODC
valid_defaults:
  - o2
  - o2-dataflow
  - o2-epn
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
