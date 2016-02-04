package: nanomsg
version: master
source: https://github.com/nanomsg/nanomsg
tag: master
build_requires:
  - autotools
---
#!/bin/sh
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
./autogen.sh 
./configure --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make install
