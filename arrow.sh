package: arrow
version: "v14.0.1-alice1"
tag: apache-arrow-14.0.1-alice1
source: https://github.com/alisw/arrow.git
requires:
  - boost
  - lz4
  - Clang:(?!.*osx)
  - protobuf
  - utf8proc
  - OpenSSL:(?!osx)
  - xsimd
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
#!/bin/bash -e
mkdir -p "$INSTALLROOT"
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ -z $FLATBUFFERS_ROOT ]] && FLATBUFFERS_ROOT=$(dirname "$(dirname "$(which flatc)")")
    [[ -z $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    [[ -z $LZ4_ROOT ]] && LZ4_ROOT=$(dirname "$(dirname "$(which lz4)")")
    [[ -z $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(dirname "$(dirname "$(which protoc)")")
    [[ -z $UTF8PROC_ROOT ]] && UTF8PROC_ROOT=$(brew --prefix utf8proc)
    [[ ! -d $FLATBUFFERS_ROOT ]] && unset FLATBUFFERS_ROOT
    [[ ! -d $BOOST_ROOT ]] && unset BOOST_ROOT
    [[ ! -d $LZ4_ROOT ]] && unset LZ4_ROOT
    [[ ! -d $PROTOBUF_ROOT ]] && unset PROTOBUF_ROOT
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
  osx*)
   CLANG_EXECUTABLE=/usr/bin/clang
   ;;
  *)
   CLANG_EXECUTABLE=${CLANG_ROOT}/bin-safe/clang
   # this patches version script to hide llvm symbols in gandiva library
   sed -i.deleteme '/^[[:space:]]*extern/ a \ \ \ \ \ \ llvm*; LLVM*;' "./src_tmp/cpp/src/gandiva/symbols.map"
   ;;
esac

cmake ./src_tmp/cpp                                                                                 \
      ${CMAKE_SHARED_LINKER_FLAGS:+-DCMAKE_SHARED_LINKER_FLAGS="$CMAKE_SHARED_LINKER_FLAGS"}        \
      -DARROW_DEPENDENCY_SOURCE=SYSTEM                                                              \
      -DCMAKE_BUILD_TYPE=Release                                                                    \
      -DCMAKE_CXX_STANDARD=17                                                                       \
      -DBUILD_SHARED_LIBS=TRUE                                                                      \
      -DARROW_BUILD_BENCHMARKS=OFF                                                                  \
      -DARROW_BUILD_TESTS=OFF                                                                       \
      -DARROW_ENABLE_TIMING_TESTS=OFF                                                               \
      -DARROW_USE_GLOG=OFF                                                                          \
      -DARROW_JEMALLOC=OFF                                                                          \
      -DARROW_HDFS=OFF                                                                              \
      -DARROW_IPC=ON                                                                                \
      ${THRIFT_ROOT:+-DARROW_PARQUET=ON}                                                            \
      ${THRIFT_ROOT:+-DThrift_ROOT="$THRIFT_ROOT"}                                                  \
      ${FLATBUFFERS_ROOT:+-DFlatbuffers_ROOT="$FLATBUFFERS_ROOT"}                                   \
      -DCMAKE_INSTALL_LIBDIR="lib"                                                                  \
      -DARROW_WITH_LZ4=ON                                                                           \
      ${RAPIDJSON_ROOT:+-DRapidJSON_ROOT="$RAPIDJSON_ROOT"}                                         \
      ${RE2_ROOT:+-DRE2_ROOT="$RE2_ROOT"}                                                           \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY="$PROTOBUF_ROOT/lib/libprotobuf.$SONAME"}                 \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY="$PROTOBUF_ROOT/lib/libprotobuf-lite.$SONAME"}       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY="$PROTOBUF_ROOT/lib/libprotoc.$SONAME"}            \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR="$PROTOBUF_ROOT/include"}                             \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE="$PROTOBUF_ROOT/bin/protoc"}                    \
      ${BOOST_ROOT:+-DBoost_ROOT="$BOOST_ROOT"}                                                     \
      ${LZ4_ROOT:+-DLZ4_ROOT="$LZ4_ROOT"}                                                           \
      ${UTF8PROC_ROOT:+-Dutf8proc_ROOT="$UTF8PROC_ROOT"}                                            \
      ${OPENSSL_ROOT:+-DOpenSSL_ROOT="$OPENSSL_ROOT"}                                               \
      ${CLANG_ROOT:+-DLLVM_DIR="$CLANG_ROOT"}                                                       \
      -DARROW_WITH_SNAPPY=OFF                                                                       \
      -DARROW_WITH_ZSTD=OFF                                                                         \
      -DARROW_WITH_BROTLI=OFF                                                                       \
      -DARROW_WITH_ZLIB=ON                                                                          \
      -DARROW_NO_DEPRECATED_API=ON                                                                  \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                         \
      -DARROW_PYTHON=OFF                                                                            \
      -DARROW_TENSORFLOW=ON                                                                         \
      -DARROW_GANDIVA=ON                                                                            \
      -DARROW_COMPUTE=ON                                                                            \
      -DARROW_BUILD_STATIC=OFF                                                                      \
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON                                                        \
      -DCLANG_EXECUTABLE="$CLANG_EXECUTABLE"

make ${JOBS:+-j $JOBS}
make install
find "$INSTALLROOT/share" -name '*-gdb.py' -exec mv {} "$INSTALLROOT/lib" \;

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --lib --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
