package: root
version: v5-34-08-alice9
source: http://github.com/alisw/root
tag: 1f141fd8d5d21efd2a3af3569ff34f4f121b2656
requires:
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
