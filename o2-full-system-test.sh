package: O2-full-system-test
version: "1.0"
requires:
  - O2Suite
  - O2sim
force_rebuild: 1
---
#!/bin/bash -e

echo TEST ----------- env
echo df:
df
echo -----
echo ls /tmp
ls -al /tmp
echo -----
echo env:
env
echo readlink:
readlink /proc/self/exe || true
echo END TEST ------- env

rm -Rf $BUILDDIR/full-system-test-sim
mkdir $BUILDDIR/full-system-test-sim
pushd $BUILDDIR/full-system-test-sim
export JOBUTILS_PRINT_ON_ERROR=1
export JOBUTILS_JOB_TIMEOUT=900
export NHBPERTF=128
export SHMSIZE=8000000000
ALICE_O2SIM_DUMPLOG=1 NEvents=5 NEventsQED=100 O2SIMSEED=12345 $O2_ROOT/prodtests/full_system_test.sh
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
