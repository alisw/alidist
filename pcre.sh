package: PCRE
version: master
source: https://github.com/ktf/pcre
tag: master
---
#!/bin/sh
$SOURCEDIR/configure --enable-unicode-properties \
                     --enable-pcregrep-libz \
                     --enable-pcregrep-libbz2 \
                     --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
