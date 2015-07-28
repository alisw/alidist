package: AliRoot-test
version: v1
force_rebuild: 1
requires:
  - AliPhysics
  - GEANT3
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: $x STARTED"
# Despite the fact we shouldn't rely on external variables, here we do to
# control from the outside (i.e. jenkins) which tests to run.
for x in ${ALI_CI_TESTS:-ppbench gun}; do
  cp -r $ALIROOT_ROOT/test/$x .
  cd $x
  set -o pipefail
  if ./runtest.sh ; then
    STATUS=SUCCESS
  else
    STATUS=FAILED
  fi
  mkdir -p  $WORKSPACE/$x
  find . -name "*.root" -exec cp {} $WORKSPACE/$x \;
  echo "`date +%s`:aliroot-test: $x $STATUS"
done
