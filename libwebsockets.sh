package: libwebsockets
version: "%(tag_basename)s"
tag: "v2.4.2"
source: https://github.com/warmcat/libwebsockets
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
cmake $SOURCEDIR/                           \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_BUILD_TYPE=RELEASE            \
      -DLWS_WITH_STATIC=ON                  \
      -DLWS_WITH_SHARED=OFF                 \
      -DLWS_WITHOUT_TESTAPPS=ON
make ${JOBS+-j $JOBS} install
rm -rf $INSTALLROOT/share
