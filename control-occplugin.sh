package: Control-OCCPlugin
version: "%(tag_basename)s"
tag: "v1.9.0"
requires:
  - FairMQ
  - FairLogger
  - boost
  - grpc
  - protobuf
  - "GCC-Toolchain:(?!osx)"
  - libInfoLogger
  - Configuration
build_requires:
  - RapidJSON
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Control
incremental_recipe: |
  make ${JOBS+-j $JOBS} prefix=$INSTALLROOT
  make prefix=$INSTALLROOT install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

SONAME=so
case $ARCHITECTURE in
    osx*)
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
      [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(brew --prefix protobuf)
      [[ ! $GRPC_ROOT ]] && GRPC_ROOT=$(brew --prefix grpc)
      [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
      SONAME=dylib
    ;;
esac

cmake $SOURCEDIR/occ                                                                     \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                \
      ${BOOST_ROOT:+-DBOOSTPATH=$BOOST_ROOT}                                             \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR}                          \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include}                      \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DGRPCPATH=${GRPC_ROOT}                                                            \
      -DPROTOBUFPATH=${PROTOBUF_ROOT}                                                    \
      -DFAIRMQPATH=${FAIRMQ_ROOT}                                                        \
      -DFAIRLOGGERPATH=${FAIRLOGGER_ROOT}                                                \
      ${RAPIDJSON_ROOT:+-DRapidJSON_ROOT=${RAPIDJSON_ROOT}}                              \
      -DConfiguration_ROOT=$CONFIGURATION_ROOT                                           \
      -DBUILD_SHARED_LIBS=ON

make ${JOBS+-j $JOBS} prefix=$INSTALLROOT
make prefix=$INSTALLROOT install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
