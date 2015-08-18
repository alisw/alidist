package: ROOT
version: v5-34-30-alice2
source: https://github.com/alisw/root
requires: 
  - CMake
  - AliEn
  - GSL
env:
  ROOTSYS: "$ROOT_ROOT"
---
#!/bin/bash -e

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

export ROOTSYS=$BUILDDIR
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
  --enable-builtin-pcre \
  --enable-mathmore \
  ${ENABLE_COCOA+--enable-cocoa} \
  --disable-bonjour \
  ${DISABLE_FINK+--disable-fink} \
  --with-f77=gfortran \
  --with-cc=$COMPILER_CC \
  --with-cxx=$COMPILER_CXX \
  --with-ld=$COMPILER_LD \
  ${WITH_CLANG+--with-clang} \
  --disable-shadowpw

./bin/root-config --features | grep -q alien
./bin/root-config --features | grep -q opengl

make ${JOBS+-j $JOBS}
export ROOTSYS=$INSTALLROOT
make install
