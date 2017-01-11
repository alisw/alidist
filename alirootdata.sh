package: AliRootData
version: "%(commit_hash)s"
tag: master
source: https://gitlab.cern.ch/alisw/AliRootData.git
---
#!/bin/bash -e
rsync -a --exclude='**/.git' $SOURCEDIR/ $INSTALLROOT/
