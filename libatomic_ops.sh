package: libatomic_ops
version: libatomic_ops-7_4_2
tag: master
license: GPL-2.0
source: https://github.com/ivmai/libatomic_ops/
build_requires:
  - "autotools:(slc6|slc7)"
  - GCC-Toolchain
---
#!/bin/sh
rsync -a $SOURCEDIR/ ./
libtoolize
autoreconf -ivf
./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
