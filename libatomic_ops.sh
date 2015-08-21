package: libatomic_ops
version: libatomic_ops-7_4_2
source: https://github.com/ivmai/libatomic_ops/
tag: master
requires:
  - autotools:slc5.*
---
#!/bin/sh
rsync -a $SOURCEDIR/ ./
libtoolize
autoreconf -ivf
./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
