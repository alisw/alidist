package: ZeroMQ
version: master
source: https://github.com/ktf/libzmq
tag: master
requires:
  - sodium
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"zmq.h\"\n" | gcc -I$(brew --prefix zeromq)/include -xc++ - -c -M 2>&1
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
