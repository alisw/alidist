package: Control-OCCPlugin
version: "%(tag_basename)s"
tag: "v0.12.91"
requires:
  - FairMQ
  - FairLogger
  - boost
  - grpc
  - protobuf
  - "GCC-Toolchain:(?!osx)"
  - libInfoLogger
build_requires:
  - grpc
  - CMake
source: https://github.com/AliceO2Group/Control
incremental_recipe: |
  make ${JOBS+-j $JOBS} prefix=$INSTALLROOT
  make prefix=$INSTALLROOT install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

LIBEXT=so
case $ARCHITECTURE in
    osx*)
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
      [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(brew --prefix protobuf)
      [[ ! $GRPC_ROOT ]] && GRPC_ROOT=$(brew --prefix grpc)
      [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl)
      LIBEXT=dylib
    ;;
esac

cmake $SOURCEDIR/occ                                                                     \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                \
      ${BOOST_ROOT:+-DBOOSTPATH=$BOOST_ROOT}                                             \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR}                          \
      -DGRPCPATH=${GRPC_ROOT}                                                            \
      -DPROTOBUFPATH=${PROTOBUF_ROOT}                                                    \
      -DFAIRMQPATH=${FAIRMQ_ROOT}                                                        \
      -DFAIRLOGGERPATH=${FAIRLOGGER_ROOT}

make ${JOBS+-j $JOBS} prefix=$INSTALLROOT
make prefix=$INSTALLROOT install

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
module load BASE/1.0 \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PROTOBUF_REVISION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION} \\
            ${FAIRMQ_REVISION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION} \\
            ${FAIRLOGGER_REVISION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION} \\
            ${GRPC_REVISION:+grpc/$GRPC_VERSION-$GRPC_REVISION} \\
            ${LIBINFOLOGGER_REVISION:+libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION}

# Our environment
set CONTROL_OCCPLUGIN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv CONTROL_OCCPLUGIN_ROOT \$CONTROL_OCCPLUGIN_ROOT
prepend-path PATH \$CONTROL_OCCPLUGIN_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CONTROL_OCCPLUGIN_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
