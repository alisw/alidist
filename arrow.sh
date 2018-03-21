package: arrow
version: v0.8.0
tag: apache-arrow-0.8.0
source: https://github.com/apache/arrow
requires:
  - flatbuffers
  - boost
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
---
mkdir -p $INSTALLROOT
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FLATBUFFERS_ROOT ]] && FLATBUFFERS_ROOT=`brew --prefix flatbuffers`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

FLATBUFFERS_HOME=$FLATBUFFERS_ROOT            \
cmake $SOURCEDIR/cpp                          \
      -DARROW_BUILD_BENCHMARKS=OFF            \
      -DARROW_BUILD_TESTS=OFF                 \
      -DARROW_JEMALLOC=OFF                    \
      -DARROW_HDFS=OFF                        \
      -DARROW_IPC=OFF                         \
      -DARROW_USE_SSE=ON                      \
      -DARROW_WITH_LZ4=ON                     \
      -DARROW_WITH_SNAPPY=OFF                 \
      -DARROW_WITH_GRPC=OFF                   \
      -DARROW_WITH_ZSTD=ON                    \
      -DARROW_WITH_ZLIB=ON                    \
      -DARROW_NO_DEPRECATED_API=ON            \
      -DBOOST_ROOT=$BOOST_ROOT                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
      -DARROW_PYTHON=OFF

make ${JOBS:+-j $JOBS}
make install

#ModuleFil
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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${FLATBUFFERS_VERSION:+flatbuffers/${FLATBUFFERS_VERSION}-${FLATBUFFERS_REVISION}}
# Our environment
setenv ARROW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ARROW_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ARROW_ROOT)/lib")
prepend-path PATH \$::env(ARROW_ROOT)/bin
EoF
