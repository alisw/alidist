package: libunwind
version: v1.6.2
source: http://github.com/libunwind/libunwind
build_requires:
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
