package: OCDB-test
version: "%(short_hash)s"
requires:
  - ROOT
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot 
tag: v5-07-10
---
#!/bin/sh
rsync -av $SOURCEDIR/OCDB/ $INSTALLROOT/
