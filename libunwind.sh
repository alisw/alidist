package: libunwind
version: master
source: https://github.com/igprof/libunwind
tag: master
requires:
  - libatomic_ops
---
#!/bin/sh
(cd $SOURCEDIR && autoreconf -i)
$SOURCEDIR/configure \
  CPPFLAGS="-I$LIBATOMIC_OPS_ROOT/include" \
  CFLAGS="-g -O3" \
  --prefix=$INSTALLROOT \
  --disable-block-signals

make ${JOBS+-j $JOBS}
make install
