package: AliRoot-test
version: v1
force_rebuild: 1
requires:
  - AliRoot
  - GEANT3
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: gun STARTED"
cp -r $ALIROOT_ROOT/test/gun .
cd gun
set -o pipefail 
if ./runtest.sh ; then
  STATUS=SUCCESS
else
  STATUS=FAILED
fi
mkdir -p  $WORKSPACE/gun
find . -name "*.root" -exec cp {} $WORKSPACE/gun \;
echo "`date +%s`:aliroot-test: gun $STATUS"
