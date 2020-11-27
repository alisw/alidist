package: arrow
version: "v1.0.0"
tag: 785e31087
source: https://github.com/alisw/arrow.git
requires:
  - boost
  - lz4
  - Clang
  - protobuf
  - utf8proc
build_requires:
  - zlib
  - flatbuffers
  - RapidJSON
  - CMake
  - double-conversion
  - re2
  - alibuild-recipe-tools
env:
  ARROW_HOME: "$ARROW_ROOT"
---

mkdir -p $INSTALLROOT
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FLATBUFFERS_ROOT ]] && FLATBUFFERS_ROOT=$(dirname $(dirname $(which flatc)))
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    [[ ! $LZ4_ROOT ]] && LZ4_ROOT=$(dirname $(dirname $(which lz4)))
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(dirname $(dirname $(which protoc)))
    [[ ! $UTF8PROC_ROOT ]] && UTF8PROC_ROOT=$(brew --prefix utf8proc)
    [[ ! -d $FLATBUFFERS_ROOT ]] && unset FLATBUFFERS_ROOT
    [[ ! -d $BOOST_ROOT ]] && unset BOOST_ROOT
    [[ ! -d $LZ4_ROOT ]] && unset LZ4_ROOT
    [[ ! -d $PROTOBUF_ROOT ]] && unset PROTOBUF_ROOT
    MACOSX_RPATH=OFF
    SONAME=dylib
    cat >no-llvm-symbols.txt << EOF
_LLVM*
__ZN4llvm*
__ZNK4llvm*
EOF
    CMAKE_SHARED_LINKER_FLAGS="-Wl,-unexported_symbols_list,$PWD/no-llvm-symbols.txt"
  ;;
  *) SONAME=so ;;
esac

# Downloaded by CMake, built, and linked statically (not needed at runtime):
#   zlib, lz4, brotli
#
# Taken from our stack, linked statically (not needed at runtime):
#   flatbuffers
#
# Taken from our stack, linked dynamically (needed at runtime):
#   boost

mkdir -p ./src_tmp
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./src_tmp/

case $ARCHITECTURE in
  osx*) ;;
  *)
   # this patches version script to hide llvm symbols in gandiva library
   sed -i.deleteme '/^[[:space:]]*extern/ a \ \ \ \ \ \ llvm*; LLVM*;' "./src_tmp/cpp/src/gandiva/symbols.map"
   ;;
esac

cmake ./src_tmp/cpp                                                                                 \
      ${CMAKE_SHARED_LINKER_FLAGS:+-DCMAKE_SHARED_LINKER_FLAGS=${CMAKE_SHARED_LINKER_FLAGS}}        \
      -DARROW_DEPENDENCY_SOURCE=SYSTEM                                                              \
      -DCMAKE_BUILD_TYPE=Release                                                                    \
      -DCMAKE_CXX_STANDARD=17                                                                       \
      -DBUILD_SHARED_LIBS=TRUE                                                                      \
      -DARROW_BUILD_BENCHMARKS=OFF                                                                  \
      -DARROW_BUILD_TESTS=OFF                                                                       \
      -DARROW_USE_GLOG=OFF                                                                          \
      -DARROW_JEMALLOC=OFF                                                                          \
      -DARROW_HDFS=OFF                                                                              \
      -DARROW_IPC=ON                                                                                \
      ${THRIFT_ROOT:+-DARROW_PARQUET=ON}                                                            \
      ${THRIFT_ROOT:+-DThrift_ROOT=${THRIFT_ROOT}}                                                  \
      ${FLATBUFFERS_ROOT:+-DFlatbuffers_ROOT=${FLATBUFFERS_ROOT}}                                   \
      -DCMAKE_INSTALL_LIBDIR="lib"                                                                  \
      -DARROW_WITH_LZ4=ON                                                                           \
      ${RAPIDJSON_ROOT:+-DRapidJSON_ROOT=${RAPIDJSON_ROOT}}                                         \
      ${RE2_ROOT:+-DRE2_ROOT=${RE2_ROOT}}                                                           \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.$SONAME}                   \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.$SONAME}         \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.$SONAME}              \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                               \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}                      \
      ${BOOST_ROOT:+-DBoost_ROOT=$BOOST_ROOT}                                                       \
      ${LZ4_ROOT:+-DLZ4_ROOT=${LZ4_ROOT}}                                                           \
      ${UTF8PROC_ROOT:+-Dutf8proc_ROOT=${UTF8PROC_ROOT}}                                            \
      -DARROW_WITH_SNAPPY=OFF                                                                       \
      -DARROW_WITH_ZSTD=OFF                                                                         \
      -DARROW_WITH_BROTLI=OFF                                                                       \
      -DARROW_WITH_ZLIB=ON                                                                          \
      -DARROW_NO_DEPRECATED_API=ON                                                                  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                           \
      -DARROW_PYTHON=OFF                                                                            \
      -DARROW_TENSORFLOW=ON                                                                         \
      -DARROW_GANDIVA=ON                                                                            \
      -DARROW_COMPUTE=ON                                                                            \
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON                                                        \
      -DCLANG_EXECUTABLE=${CLANG_ROOT}/bin-safe/clang

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ARROW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$ARROW_ROOT/lib
EoF
