package: AliRoot-test
version: v1
force_rebuild: 1
requires:
  - AliPhysics
  - GEANT3
  - OCDB-test
  - "IgProf:slc7.*"
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: $x STARTED"
WORKSPACE=${WORKSPACE:-$BUILDDIR}

# Despite the fact we shouldn't rely on external variables, here we do to
# control from the outside (i.e. jenkins) which tests to run.
#
# By default we only run gun. We do this so that before running longer tests we
# make sure that at least the simple ones are ok.
cp -r $ALIROOT_ROOT/test .
for x in ${ALI_CI_TESTS:-gun}; do
  set -o pipefail
  find test -name "*.C" -exec perl -p -i -e 's|ALICE_ROOT/OCDB|OCDB_TEST_ROOT|' {} \;
  VARIANTS=default${IGPROF_ROOT:+,igprof_memory,igprof_perf}
  if test/runTests -d --variants $VARIANTS $x; then
    STATUS=SUCCESS
  else
    STATUS=FAILED
  fi
  # Process any igprof profile dump.
  for y in $(find . -name "igprof*.gz"); do
    IGPROF_OUT=$(echo $y | sed -e's/.gz/.sql/')
    igprof-analyse -d -g $y --sqlite | sqlite3 $IGPROF_OUT
  done
  mkdir -p  ${WORKSPACE}/$x
  find . -name "*.root" -exec cp {} $WORKSPACE/$x \;
  find . -name "*.log" -exec cp {} $WORKSPACE/$x \;
  find . -name "*.sql" -exec cp {} $WORKSPACE/$x \;
  echo "`date +%s`:aliroot-test: $x $STATUS"
done
