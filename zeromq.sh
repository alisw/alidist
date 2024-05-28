package: ZeroMQ
version: v4.3.5
source: https://github.com/zeromq/libzmq
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "CMake"
  - ninja
  - alibuild-recipe-tools
---
cd $BUILDDIR
cmake $SOURCEDIR                          \
      -G Ninja                            \
      -DENABLE_WS=OFF                     \
      -DBUILD_TESTS=OFF                   \
      -DCMAKE_INSTALL_LIBDIR=lib          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

ninja ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
