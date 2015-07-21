package: libunwind
version: master
source: git://git.sv.gnu.org/libunwind.git
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
