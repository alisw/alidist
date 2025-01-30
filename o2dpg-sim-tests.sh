package: O2DPG-sim-tests
version: "1.0"
requires:
  - O2sim
force_rebuild: true
---
#!/bin/bash -e

if [[ "$G4INSTALL" != "" ]]; then
  `$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`
fi

TEST_DIR=$BUILDDIR/o2dpg-sim_tests
LOGFILE="${TEST_DIR}/o2dpg-sim-tests.log"

# remove everything for a fresh start
rm -Rf ${TEST_DIR}
mkdir ${TEST_DIR}
pushd ${TEST_DIR}

# check if LHAPDF data path is set
if [ -z "$LHAPDF_DATA_PATH" ]; then
  echo "Setting LHAPDF_DATA_PATH to $LHAPDF_ROOT/share/LHAPDF:$LHAPDF_PDFSETS_ROOT/share/LHAPDF"
  export LHAPDF_DATA_PATH=$LHAPDF_ROOT/share/LHAPDF:$LHAPDF_PDFSETS_ROOT/share/LHAPDF
fi
O2DPG_TEST_GENERATOR_EXITCODE=0
{ O2DPG_TEST_REPO_DIR=${WORK_DIR}/../O2DPG "${O2DPG_ROOT}/test/run_generator_tests.sh" &> ${LOGFILE} ; O2DPG_TEST_GENERATOR_EXITCODE=$?; } || true  # don't quit immediately on error

O2DPG_TEST_WORKFLOW_EXITCODE=0
{ O2DPG_TEST_REPO_DIR=${WORK_DIR}/../O2DPG "${O2DPG_ROOT}/test/run_workflow_tests.sh" >> ${LOGFILE} 2>&1 ; O2DPG_TEST_WORKFLOW_EXITCODE=$?; } || true  # don't quit immediately on error

O2DPG_TEST_ANALYSISQC_EXITCODE=0
{ O2DPG_TEST_REPO_DIR=${WORK_DIR}/../O2DPG "${O2DPG_ROOT}/test/run_analysisqc_tests.sh" >> ${LOGFILE} 2>&1 ; O2DPG_TEST_ANALYSISQC_EXITCODE=$?; } || true  # don't quit immediately on error

O2DPG_TEST_RELVAL_EXITCODE=0
{ O2DPG_TEST_REPO_DIR=${WORK_DIR}/../O2DPG "${O2DPG_ROOT}/test/run_relval_tests.sh" >> ${LOGFILE} 2>&1 ; O2DPG_TEST_RELVAL_EXITCODE=$?; } || true  # don't quit immediately on error

cat ${LOGFILE}

if [ "${O2DPG_TEST_GENERATOR_EXITCODE}" != "0" -o "${O2DPG_TEST_WORKFLOW_EXITCODE}" != "0" -o "${O2DPG_TEST_ANALYSISQC_EXITCODE}" != "0" -o "${O2DPG_TEST_RELVAL_EXITCODE}" != "0" ] ; then
  # something is wrong
  echo "error detected in ${PKGNAME}, see above"
  # make the recipe fail
  false
else
  echo "${PKGNAME} passed"
fi

popd

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
module load BASE/1.0 O2sim/$O2SIM_VERSION-$O2SIM_REVISION
EoF
