package: O2DPG-sim-tests
version: "1.0"
requires:
  - O2sim
force_rebuild: 1
---
#!/bin/bash -e

if [[ "$G4INSTALL" != "" ]]; then
  `$G4INSTALL/bin/geant4-config --datasets | sed 's/[^ ]* //' | sed 's/G4/export G4/' | sed 's/DATA /DATA=/'`
fi

rm -Rf $BUILDDIR/o2dpg-sim_tests
mkdir $BUILDDIR/o2dpg-sim_tests
pushd $BUILDDIR/o2dpg-sim_tests

LOGFILE="o2dpg-sim-tests.log"

O2DPG_TEST_EXITCODE=0
{ O2DPG_TEST_REPO_DIR=${SOURCEDIR}/../../../O2DPG/${O2DPG_VERSION}/0 "${O2DPG_ROOT}/test/run_generator_tests.sh" &> ${LOGFILE} ; O2DPG_TEST_EXITCODE=$?; } || true  # don't quit immediately on error
# keep only logs, remove everything else for now
# if we needed/possible in the future, we might keep some of the other files
find . -type f ! -name '*.log' -and ! -name "*serverlog*" -and ! -name "*mergerlog*" -and ! -name "*workerlog*" -delete
if [ ${O2DPG_TEST_EXITCODE} != "0" ] ; then
  # something is wrong
  echo "error detected in ${PKGNAME}"
  cat ${LOGFILE}
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
