package: protobuf
version: v3.15.8
source: https://github.com/google/protobuf
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
---

cmake $SOURCEDIR/cmake                  \
    -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
    -Dprotobuf_BUILD_TESTS=NO           \
    -Dprotobuf_MODULE_COMPATIBLE=YES    \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF    \
    -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j $JOBS}
make install

#ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env > "$MODULEDIR/$PKGNAME"
