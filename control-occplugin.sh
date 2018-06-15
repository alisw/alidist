package: Control-OCCPlugin
version: "v%(year)s%(month)s%(day)s-%(commit_hash)s"
tag:  master
requires:
  - FairMQ
  - FairLogger
  - boost
  - grpc
  - protobuf
  - "GCC-Toolchain:(?!osx)"
build_requires:
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
      LIBEXT=dylib
    ;;
esac

cmake $SOURCEDIR/occplugin                                                               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                \
      ${BOOST_ROOT:+-DBOOSTPATH=$BOOST_ROOT}                                             \
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
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PROTOBUF_VERSION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION} \\
            ${FAIRMQ_VERSION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION} \\
            ${FAIRLOGGER_VERSION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION} \\
            ${GRPC_VERSION:+grpc/$GRPC_VERSION-$GRPC_REVISION}

# Our environment
setenv CONTROL_OCCPLUGIN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CONTROL_OCCPLUGIN_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(CONTROL_OCCPLUGIN_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(CONTROL_OCCPLUGIN_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
