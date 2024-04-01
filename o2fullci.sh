package: O2FullCI
version: "1.0.0"
tag: "O2FullCI-1.0.0"
requires:
  - O2Suite
  - o2checkcode
  - O2-full-system-test
  - O2-sim-challenge-test
  - O2-RTC-test
valid_defaults:
  - o2
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
