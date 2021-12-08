package: O2-full-system-test
version: "1.0"
requires:
  - O2Suite
  - O2sim
  - O2DPG
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

# we also run the sim_challeng.sh script to check a basic MC workflow (including AOD)
rm -Rf $BUILDDIR/sim-challenge
mkdir $BUILDDIR/sim-challenge
pushd $BUILDDIR/sim-challenge
SIM_CHALLENGE_ANATESTING=ON $O2_ROOT/prodtests/sim_challenge.sh &> sim-challenge.log
grep "Return status" sim-challenge.log | grep -v ": 0" && false
popd
rm -Rf $BUILDDIR/sim-challenge

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
