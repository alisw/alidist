package: O2-full-system-test
version: "1.0"
requires:
  - O2
  - O2DPG
  - QualityControl
  - O2sim
  - O2Physics
  - jq
force_rebuild: true
---
#!/bin/bash -e

if [[ "$G4INSTALL" != "" ]]; then
  `$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`
fi

rm -Rf $BUILDDIR/full-system-test-sim
mkdir $BUILDDIR/full-system-test-sim
pushd $BUILDDIR/full-system-test-sim
export JOBUTILS_PRINT_ON_ERROR=1
export JOBUTILS_JOB_TIMEOUT=2400
export PRINT_WORKFLOW=1
export NHBPERTF=128
export SHMSIZE=8000000000
export NJOBS="$JOBS"
export DPL_REPORT_PROCESSING=1

WORKFLOW_EXTRA_PROCESSING_STEPS=TPC_DEDX,MFT_RECO,MID_RECO,MCH_RECO,MATCH_MFTMCH,MATCH_MCHMID,MUON_SYNC_RECO,ZDC_RECO FST_SYNC_EXTRA_WORKFLOW_PARAMETERS=QC,CALIB_LOCAL_AGGREGATOR,CALIB_LOCAL_INTEGRATED_AGGREGATOR QC_REDIRECT_MERGER_TO_LOCALHOST=1 GEN_TOPO_WORKDIR=`pwd` ALICE_O2SIM_DUMPLOG=1 NEvents=5 NEventsQED=100 O2SIMSEED=12345 $O2_ROOT/prodtests/full_system_test.sh
$O2_ROOT/prodtests/full_system_test_ci_extra_tests.sh
popd
rm -Rf $BUILDDIR/full-system-test-sim

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
