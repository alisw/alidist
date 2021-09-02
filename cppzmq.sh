package: cppzmq
version: v4.7.1
source: https://github.com/zeromq/cppzmq
requires:
  - "GCC-Toolchain:(?!osx)"
  - ZeroMQ
build_requires:
  - "CMake"
  - ninja
  - alibuild-recipe-tools
---
#!/bin/sh
cd $BUILDDIR
case $ARCHITECTURE in
  osx*)
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
  ;;
esac
cmake $SOURCEDIR                              \
      -G Ninja                                \
      -DZeroMQ_ROOT=$ZEROMQ_ROOT   \
      -DCPPZMQ_BUILD_TESTS=OFF      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     
ninja ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
