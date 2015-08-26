package: Clang
version: "3.6"
source: https://github.com/alisw/clang
tag: master
---
#!/bin/sh
cmake $SOURCEDIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"
  
make ${JOBS+-j $JOBS}
make install
case $ARCHITECTURE in
  osx*)
    ln -sf /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++ $INSTALLROOT/include
  ;;
esac
find $SOURCEDIR/tools/clang/tools/scan-build -type f -perm +111 -exec cp {} $INSTALLROOT/bin \;
find $SOURCEDIR/tools/clang/tools/scan-view -type f -perm +111 -exec cp {} $INSTALLROOT/bin \;
