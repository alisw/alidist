package: UUID
version: v2.27.1
source: https://github.com/alisw/uuid
tag: alice/v2.27.1
build_requires:
 - "GCC-Toolchain:(?!osx|slc5)"
 - autotools
---
#!/bin/sh
rsync -av --delete --exclude "**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure $([[ ${ARCHITECTURE:0:3} == osx ]] && echo --disable-shared) \
            --libdir=$INSTALLROOT/lib \
            --prefix=$INSTALLROOT \
            --disable-all-programs \
            --disable-silent-rules \
            --disable-tls \
            --disable-rpath \
            --without-ncurses \
            --enable-libuuid
make ${JOBS:+-j$JOBS} libuuid.la
mkdir -p $INSTALLROOT/lib
cp -p .libs/libuuid.a* $INSTALLROOT/lib
if [[ ${ARCHITECTURE:0:3} != osx ]]; then
  cp -p .libs/libuuid.so* $INSTALLROOT/lib
fi
mkdir -p $INSTALLROOT/include
make install-uuidincHEADERS
rm -rf $INSTALLROOT/man
