package: AliRoot-guntest
version: v1
force_rebuild: true
requires:
  - AliRoot
  - AliRoot-OCDB
---
#!/bin/bash -e

export ALICE_PHYSICS=$ALIPHYSICS_ROOT
# A simple regression test launching a Geant3 + Geant4 gun simulation + reconstruction.
# Tests if the processing runs through and yields a reasonable ESD.
# Note that the test is limited to the default OCDB.

# Set Geant4 data sets environment
[ "$G4INSTALL" != "" ] && \
`$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`

env | sort
rsync -a "$ALIROOT_ROOT"/test/vmctest/gun test
cd test/gun

# launch the simulation
./runtest.sh

# test outcome and return the error code
WITHESDCHECK=${ALIPHYSICS_REVISION:+yes} ./finalcheck.sh

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION AliRoot-OCDB/$ALIROOT_OCDB_VERSION-$ALIROOT_OCDB_REVISION
# Our environment
set ALIROOT_GUNTEST_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
