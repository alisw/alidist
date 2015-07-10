package: aliroot-test
version: v1
force_rebuild: 1
requires:
  - aliroot
  - geant3
---
#!/bin/sh
export ALICE_ROOT=$ALIROOT_ROOT
cp -r $ALIROOT_ROOT/test/gun .
cd gun
./runtest.sh 2>&1 | tee run.log
mkdir -p  $WORKSPACE/gun
cp -r *.root $WORKSPACE/gun
