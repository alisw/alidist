package: ROOT
version: v5-34-30
source: http://github.com/root-mirror/root
tag: v5-34-30
requires: 
  - CMake
  - AliEn
---
#!/bin/sh -e

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++

case $ARCHITECTURE in 
  osx*)
    ENABLE_COCOA=true
    DISABLE_FINK=true
    WITH_CLANG=true
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
  ;;
esac

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
  --enable-builtin-freetype \
  ${ENABLE_COCOA+--enable-cocoa} \
  --disable-bonjour \
  ${DISABLE_FINK+--disable-fink} \
  --with-f77=gfortran \
  --with-cc=$COMPILER_CC \
  --with-cxx=$COMPILER_CXX \
  --with-ld=$COMPILER_LD \
  ${WITH_CLANG+--with-clang} \
  --prefix="$INSTALLROOT" \
  --incdir="$INSTALLROOT/include" \
  --libdir="$INSTALLROOT/lib" \
  --datadir="$INSTALLROOT" \
  --disable-shadowpw \
  --etcdir="$INSTALLROOT/etc"

./bin/root-config --features | grep -q alien
./bin/root-config --features | grep -q opengl

make ${JOBS+-j $JOBS}
make install
