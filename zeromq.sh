package: zeromq
version: master
source: https://github.com/ktf/libzmq
tag: master
requires:
  - sodium
---
#!/bin/sh
cd $SOURCEDIR
./autogen.sh 
cd $BUILDDIR
$SOURCEDIR/configure --prefix=$INSTALLROOT \
                     --disable-dependency-tracking \
                     sodium_CFLAGS="-I$SODIUM_ROOT/include" \
                     sodium_LIBS="-L$SODIUM_ROOT/lib -lsodium"

make ${JOBS+-j $JOBS}
make install
