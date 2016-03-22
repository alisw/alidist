package: sodium
version: v1.0.8
source: https://github.com/jedisct1/libsodium
tag: 1.0.8
build_requires:
  - autotools
---
#!/bin/sh
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -i
./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
