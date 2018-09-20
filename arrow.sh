package: arrow
version: v0.10.0-alice1
tag: apache-arrow-0.10.0-alice1
source: https://github.com/alisw/arrow
requires:
  - boost
build_requires:
  - zlib
  - flatbuffers
  - CMake
  - "GCC-Toolchain:(?!osx)"
env:
  ARROW_HOME: "$ARROW_ROOT"
---
mkdir -p $INSTALLROOT
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FLATBUFFERS_ROOT ]] && FLATBUFFERS_ROOT=$(brew --prefix flatbuffers)
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
  ;;
esac

# Downloaded by CMake, built, and linked statically (not needed at runtime):
#   zlib, lz4, brotli
#
# Taken from our stack, linked statically (not needed at runtime):
#   flatbuffers
#
# Taken from our stack, linked dynamically (needed at runtime):
#   boost

cmake $SOURCEDIR/cpp                       \
      -DARROW_BUILD_BENCHMARKS=OFF         \
      -DARROW_BUILD_TESTS=OFF              \
      -DARROW_JEMALLOC=OFF                 \
      -DARROW_HDFS=OFF                     \
      -DARROW_IPC=ON                       \
      -DFLATBUFFERS_HOME=$FLATBUFFERS_ROOT \
      -DCMAKE_INSTALL_LIBDIR="lib"         \
      -DARROW_USE_SSE=ON                   \
      -DARROW_WITH_LZ4=ON                  \
      -DARROW_WITH_SNAPPY=OFF              \
      -DARROW_WITH_GRPC=OFF                \
      -DARROW_WITH_ZSTD=OFF                \
      -DARROW_WITH_ZLIB=ON                 \
      -DARROW_NO_DEPRECATED_API=ON         \
      -DBOOST_ROOT=$BOOST_ROOT             \
      -DARROW_WITH_BROTLI=ON               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DARROW_PYTHON=OFF

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv ARROW_HOME \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ARROW_HOME)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ARROW_HOME)/lib")
EoF
