package: zlib
version: v1.2.8
source: https://github.com/star-externals/zlib
tag: v1.2.8
---
#!/bin/sh

case $ARCHITECTURE in
   *_amd64_gcc4[56789]*)
     CFLAGS="-fPIC -O3 -DUSE_MMAP -DUNALIGNED_OK -D_LARGEFILE64_SOURCE=1 -msse3" \
     ./configure --prefix=$INSTALLROOT
     ;;
   *_armv7hl_gcc4[56789]* )
     CFLAGS="-fPIC -O3 -DUSE_MMAP -DUNALIGNED_OK -D_LARGEFILE64_SOURCE=1" \
     ./configure --prefix=$INSTALLROOT
     ;;
   * )
     ./configure --prefix=$INSTALLROOT
   ;;
esac

make ${JOBS+-j $JOBS}
make install
