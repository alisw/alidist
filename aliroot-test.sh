package: AliRoot-test
version: "%(year)s%(month)s%(day)s"
force_rebuild: true
requires:
  - AliPhysics
  - GEANT3
  - OCDB-test
  - "IgProf:slc7.*"
---
#!/bin/bash -e
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: $x STARTED"
WORKSPACE=${WORKSPACE:-$BUILDDIR}

# Uses the same setup as AliRoot
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  source $ALIROOT_ROOT/etc/gcov-setup.sh
fi

# Despite the fact we shouldn't rely on external variables, here we do to
# control from the outside (i.e. jenkins) which tests to run.
#
# By default we only run gun. We do this so that before running longer tests we
# make sure that at least the simple ones are ok.
rsync -a $ALIROOT_ROOT/test/ test
for x in ${ALI_CI_TESTS:-gun}; do
  set -o pipefail
  find test -name "*.C" -exec perl -p -i -e 's|ALICE_ROOT/OCDB|OCDB_TEST_ROOT|' {} \;
  VARIANTS=default${IGPROF_ROOT:+,igprof_memory,igprof_performance}
  if test/runTests -d --variants $VARIANTS $x; then
    STATUS=SUCCESS
  else
    STATUS=FAILED
  fi
  # Process any igprof profile dump (performance).
  for y in $(find . -name "igprof*PERFORMANCE.gz"); do
    IGPROF_OUT=$(echo $y | sed -e's/.gz/.sql/')
    igprof-analyse -d -g $y --sqlite | sqlite3 $IGPROF_OUT
  done
  # Process any igprof profile dump (memory).
  for y in $(find . -name "igprof*MEMORY.gz"); do
    igprof-analyse -d -r MEM_TOTAL -g $y --sqlite | sqlite3  $(echo $y | sed -e's/MEMORY.gz/MEM_TOTAL.sql/') || true
    igprof-analyse -d -r MEM_LIVE -g $y --sqlite | sqlite3 $(echo $y | sed -e's/MEMORY.gz/MEM_LIVE.sql/') || true
    igprof-analyse -d -r MEM_MAX -g $y --sqlite | sqlite3 $(echo $y | sed -e's/MEMORY.gz/MEM_MAX.sql/') || true
  done
  # Simple normalization of results. /etc/sysbench-results is created by
  # puppet on build infrastructure machines.
  if [ -f /etc/sysbench-results ]; then
    NORMALIZATION=`cat /etc/sysbench-results | grep 'total time:' | sed -e 's/[^0-9]*//;s/s//'`
  else
    NORMALIZATION=1
  fi
  for y in $(find . -name "*.sql"); do
    cat << EOF | sqlite3 $y
      CREATE TABLE metadata (key STRING, value STRING);
      INSERT INTO metadata(key, value) VALUES ('status', '$STATUS');
      INSERT INTO metadata(key, value) VALUES ('test_name', '$x');
      INSERT INTO metadata(key, value) VALUES ('architecture', '$ARCHITECTURE');
      INSERT INTO metadata(key, value) VALUES ('aliroot_version', '$ALIROOT_VERSION');
      INSERT INTO metadata(key, value) VALUES ('aliphysics_version', '$ALIPHYSICS_VERSION');
      INSERT INTO metadata(key, value) VALUES ('hostname', '$HOSTNAME');
      INSERT INTO metadata(key, value) VALUES ('normalization', '$NORMALIZATION');
EOF
  done
  mkdir -p  ${WORKSPACE}/$x
  find . -name "*.root" -exec cp {} $WORKSPACE/$x \;
  find . -name "*.log" -exec cp {} $WORKSPACE/$x \;
  find . -name "*.sql" -exec cp {} $WORKSPACE/$x \;
  echo "`date +%s`:aliroot-test: $x $STATUS"
done
