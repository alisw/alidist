package: sodium
version: master
source: https://github.com/jedisct1/libsodium
tag: master
build_requires:
  - autotools
---
#!/bin/sh
cd $SOURCEDIR
autoreconf -i
cd $BUILDDIR
$SOURCEDIR/configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
