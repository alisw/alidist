package: OCDB-test
version: "%(short_hash)s"
tag: v5-08-19
requires:
  - ROOT
license: GPL-3.0
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot
---
#!/bin/sh
rsync -av $SOURCEDIR/OCDB/ $INSTALLROOT/
