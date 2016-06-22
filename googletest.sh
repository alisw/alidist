package: googletest
version: "1.7.0"
source: https://github.com/google/googletest
tag: release-1.7.0
build_requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS+-j $JOBS}
mkdir -p $INSTALLROOT/lib
cp *.a $INSTALLROOT/lib
rsync -av $SOURCEDIR/include/ $INSTALLROOT/include/
