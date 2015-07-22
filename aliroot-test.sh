package: aliroot-test
version: v1
force_rebuild: 1
requires:
  - aliroot
  - geant3
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
echo "`date +%s`:aliroot-test: gun STARTED"
cp -r $ALIROOT_ROOT/test/gun .
cd gun
./runtest.sh 2>&1 | tee run.log
mkdir -p  $WORKSPACE/gun
cp -rf *.root $WORKSPACE/gun
echo "`date +%s`:aliroot-test: gun SUCCESS"
