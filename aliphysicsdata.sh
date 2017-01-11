package: AliPhysicsData
version: "%(commit_hash)s"
tag: master
source: https://gitlab.cern.ch/alisw/AliPhysicsData.git
---
#!/bin/bash -e
rsync -a --exclude='**/.git' $SOURCEDIR/ $INSTALLROOT/
