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
{ "${O2DPG_ROOT}/test/run_tests.sh" &> ${LOGFILE} ; O2DPG_TEST_EXITCODE=$?; } || true  # don't quit immediately on error
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
rm -Rf $BUILDDIR/o2dpg-sim_tests

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
