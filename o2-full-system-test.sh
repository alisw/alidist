package: O2-full-system-test
version: "1.0"
requires:
  - O2Suite
  - O2sim
build_requires:
  - alibuild-recipe-tools
force_rebuild: 1
---
#!/bin/bash -e

if [[ "$G4INSTALL" != "" ]]; then
  `$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`
fi

rm -Rf $BUILDDIR/full-system-test-sim
mkdir $BUILDDIR/full-system-test-sim
pushd $BUILDDIR/full-system-test-sim
export JOBUTILS_PRINT_ON_ERROR=1
export JOBUTILS_JOB_TIMEOUT=1800
export NHBPERTF=128
export SHMSIZE=8000000000
ALICE_O2SIM_DUMPLOG=1 NEvents=5 NEventsQED=100 O2SIMSEED=12345 $O2_ROOT/prodtests/full_system_test.sh
$O2_ROOT/prodtests/full_system_test_ci_extra_tests.sh
popd
rm -Rf $BUILDDIR/full-system-test-sim

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
