package: libatomic_ops
version: v1.0
source: https://github.com/igprof/libatomic_ops
tag: master
---
#!/bin/sh

$SOURCEDIR/configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
