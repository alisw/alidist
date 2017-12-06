package: Configuration
version: "%(tag_basename)s"
tag:  v1.2.0
requires:
  - curl
  - boost
  - "GCC-Toolchain:(?!osx)"
  - protobuf
  - grpc
  - Common-O2
  - RapidJSON
  - "Ppconsul:(?!osx)"
  - "MySQL:slc.*"
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Configuration
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT}                  \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include}  \
      ${COMMON_O2_VERSION:+-DCommon_ROOT=$COMMON_O2_ROOT}     \
      -DPROTOBUF_INCLUDE_DIR=${PROTOBUF_ROOT}/include         \
      -DPROTOBUF_LIBRARY=${PROTOBUF_ROOT}/lib/libprotobuf.so  \
      ${GRPC_ROOT:+-DGRPC_ROOT=${GRPC_ROOT}}                  \
      -DRAPIDJSON_INCLUDEDIR=${RAPIDJSON_ROOT}/include        \
      -DPPCONSUL_INCLUDE_DIRS=${PPCONSUL_ROOT}/include        \
      -DPPCONSUL_LIBRARY_DIRS=${PPCONSUL_ROOT}/lib            \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0                                                          \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PROTOBUF_VERSION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION} \\
            ${GRPC_VERSION:+grpc/$GRPC_VERSION-$GRPC_REVISION}                \\
            Ppconsul/$PPCONSUL_VERSION-$PPCONSUL_REVISION                     \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION

# Our environment
setenv Configuration_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(Configuration_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(Configuration_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
