package: O2-full-system-test
version: "1.0"
requires:
  - O2
  - O2DPG
  - QualityControl
  - O2sim
  - O2Physics
  - jq
license: GPL-3.0
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

# Optional perf profiling of the whole full-system-test production. Enable with
# USE_PERF=1. We wrap the top-level full_system_test.sh: perf record follows the
# child process tree, so every dpl-workflow.sh / o2-sim / reco device it spawns
# is sampled, with no per-workflow wiring needed. The sampling command is
# overridable via ALIBUILD_PERF_COMMAND. perf.data lands in the run directory and
# is turned into a text report (perf script) below; both go to the artifacts dir.
PERF_CMD=()
if [[ -n "$USE_PERF" ]]; then
  if ! type perf >/dev/null 2>&1; then
    echo "O2-full-system-test: USE_PERF set but 'perf' was not found in PATH; running without profiling." >&2
  elif ! perf record -o /dev/null -- true >/dev/null 2>&1; then
    # perf is installed but sampling is not permitted (e.g. perf_event_paranoid
    # too high, or no CAP_PERFMON in the container). Skip gracefully instead of
    # letting 'perf record' abort the whole production.
    echo "O2-full-system-test: USE_PERF set but 'perf record' is not permitted here" \
         "(check /proc/sys/kernel/perf_event_paranoid); running without profiling." >&2
  else
    : "${ALIBUILD_PERF_COMMAND:=perf record -e cycles:u --compression-level=5 -F 49 -g --call-graph dwarf,2048 --user-callchains}"
    read -r -a PERF_CMD <<< "$ALIBUILD_PERF_COMMAND"
    # Always write to an explicit file; without -o some perf builds stream the
    # raw perf.data to stdout, which then pollutes the production log.
    PERF_CMD+=(-o "$(pwd)/perf.data")
    echo "O2-full-system-test: perf profiling enabled -> ${PERF_CMD[*]}"
  fi
fi

WORKFLOW_EXTRA_PROCESSING_STEPS=TPC_DEDX,MFT_RECO,MID_RECO,MCH_RECO,MATCH_MFTMCH,MATCH_MCHMID,MUON_SYNC_RECO,ZDC_RECO FST_SYNC_EXTRA_WORKFLOW_PARAMETERS=QC,CALIB_LOCAL_AGGREGATOR,CALIB_LOCAL_INTEGRATED_AGGREGATOR QC_REDIRECT_MERGER_TO_LOCALHOST=1 GEN_TOPO_WORKDIR=`pwd` ALICE_O2SIM_DUMPLOG=1 OrbitsBeforeTf=0 NEvents=5 NEventsQED=100 O2SIMSEED=12345 DO_EMBEDDING=1 "${PERF_CMD[@]}" $O2_ROOT/prodtests/full_system_test.sh || FST_RC=$?

# Copy logs to artifacts directory for ali-bot upload
mkdir -p $BUILDDIR/../artifacts
find $BUILDDIR/full-system-test-sim -name '*.log' -exec cp {} $BUILDDIR/../artifacts/ \; 2>/dev/null || true

# Turn the perf recording into a text report and stash both in the artifacts dir
# (done before any cleanup/early-exit so the profile survives a failed run).
if [[ -n "$USE_PERF" && -f perf.data ]]; then
  echo "O2-full-system-test: generating perf text report (perf script -i perf.data)"
  perf script -i perf.data > perf.script.txt 2>/dev/null || echo "O2-full-system-test: 'perf script' failed" >&2
  cp perf.script.txt $BUILDDIR/../artifacts/ 2>/dev/null || true
  gzip $BUILDDIR/../artifacts/perf.script.txt
fi

if [[ ${FST_RC:-0} -ne 0 ]]; then
  rm -Rf $BUILDDIR/full-system-test-sim
  exit $FST_RC
fi

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
