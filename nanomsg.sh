package: nanomsg
version: v0.8
source: https://github.com/nanomsg/nanomsg
tag: 0.8-beta
build_requires:
  - autotools
---
#!/bin/sh
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
./autogen.sh 
./configure --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make install
