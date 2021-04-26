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

echo TEST trace dlopen
rm -Rf $BUILDDIR/full-system-test-sim-test
mkdir $BUILDDIR/full-system-test-sim-test
pushd $BUILDDIR/full-system-test-sim-test

cat >trace_dlopen.c <<EOF
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>

void* dlopen(const char *filename, int flags) {
  void* (*libc_dlopen)(const char *filename, int flags) = dlsym(RTLD_NEXT, "dlopen");
  void* res = libc_dlopen(filename, flags);
  printf("dlopen(\"%s\", %x) = %p\n", filename, flags, res);
  return res;
}
EOF
gcc -c -g -fpic trace_dlopen.c
gcc -ldl -shared -o trace_dlopen.so trace_dlopen.o
LD_PRELOAD=./trace_dlopen.so fairmq-bsampler 2>&1 || true

echo --------------- END TEST fairmq-bsampler -------------------------

LD_PRELOAD=./trace_dlopen.so o2-sim --seed -1 -j 64 -n100 -m PIPE ITS MFT FT0 FV0 FDD -g extgen --configKeyValues "GeneratorExternal.fileName=$O2_ROOT/share/Generators/external/QEDLoader.C;QEDGenParam.yMin=-7;QEDGenParam.yMax=7;QEDGenParam.ptMin=0.001;QEDGenParam.ptMax=1.;Diamond.width[2]=6." 2>&1

popd
rm -Rf $BUILDDIR/full-system-test-sim-test
echo END TEST dlopen

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
