package: root
version: v5-34-30
source: http://github.com/root-mirror/root
tag: v5-34-30
requires: 
  - cmake
  - alien
---
#!/bin/sh -e
"$SOURCEDIR/configure" \
  --with-pythia6-uscore=SINGLE \
  --with-alien-incdir=$ALIEN_ROOT/alien/api/include \
  --with-alien-libdir=$ALIEN_ROOT/alien/api/lib \
  --with-monalisa-incdir="$ALIEN_ROOT/alien/api/include" \
  --with-monalisa-libdir="$ALIEN_ROOT/alien/api/lib" \
  --with-xrootd=$ALIEN_ROOT/alien/api \
  --enable-minuit2 \
  --enable-roofit \
  --enable-soversion \
  --disable-bonjour \
  --enable-builtin-freetype \
  --with-f77=gfortran \
  --with-cc=gcc \
  --with-cxx=g++ \
  --with-ld=g++ \
  --prefix="$INSTALLROOT" \
  --incdir="$INSTALLROOT/include" \
  --libdir="$INSTALLROOT/lib" \
  --datadir="$INSTALLROOT" \
  --etcdir="$INSTALLROOT/etc"

./bin/root-config --features | grep -q alien
./bin/root-config --features | grep -q opengl

make ${JOBS+-j $JOBS}
make install
