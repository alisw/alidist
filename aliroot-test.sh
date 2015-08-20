package: AliRoot-test
version: v1
force_rebuild: 1
requires:
  - AliPhysics
  - GEANT3
  - OCDB-test
  - "IgProf:(?!osx).*"
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: $x STARTED"
# Despite the fact we shouldn't rely on external variables, here we do to
# control from the outside (i.e. jenkins) which tests to run.
#
# By default we only run gun. We do this so that before running longer tests we
# make sure that at least the simple ones are ok.
for x in ${ALI_CI_TESTS:-gun}; do
  cp -r $ALIROOT_ROOT/test/$x .
  cd $x
  set -o pipefail
  perl -p -i -e 's|ALICE_ROOT/OCDB|OCDB_TEST_ROOT|' *.C
  if ./runtest.sh ; then
    STATUS=SUCCESS
  else
    STATUS=FAILED
  fi
  mkdir -p  $WORKSPACE/$x
  find . -name "*.root" -exec cp {} $WORKSPACE/$x \;
  echo "`date +%s`:aliroot-test: $x $STATUS"
done
