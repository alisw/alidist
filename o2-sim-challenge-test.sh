package: O2-sim-challenge-test
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

export JOBUTILS_PRINT_ON_ERROR=1
export JOBUTILS_JOB_TIMEOUT=2400
export NJOBS="$JOBS"
export DPL_REPORT_PROCESSING=1

rm -Rf $BUILDDIR/sim-challenge
mkdir $BUILDDIR/sim-challenge
pushd $BUILDDIR/sim-challenge
SIMEXITCODE=0
# SIM_CHALLENGE_ANATESTING=ON --> reenable when we want analysis testing be part of the tests 
{ "$O2_ROOT/prodtests/sim_challenge.sh" &> sim-challenge.log; SIMEXITCODE=$?; } || true  # don't quit immediately on error
result=$(grep "Return status" sim-challenge.log | grep -v ": 0" || true)
if [ ${SIMEXITCODE} != "0" ] || [ "${result}" ]; then
  # something is wrong if we get a match here
  # it matches if either the return code itself was != 0 or if a reported status
  # in the log is not ok
  echo "error detected in sim_challenge"
  find ./ -type f \( -name "*.log" -and ! -name "pipel*" \) -exec awk ' { print FILENAME $0 } ' {} ';' || true
  # make the recipe fail
  false
else
  echo "sim_challenge passed"
fi
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
