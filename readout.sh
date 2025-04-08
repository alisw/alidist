package: Readout
version: "%(tag_basename)s"
tag: v2.27.2
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - libInfoLogger
  - FairMQ
  - FairLogger
  - Monitoring
  - Configuration
  - "ReadoutCard:(slc.*_x86-64)"
  - lz4
  - Control-OCCPlugin
  - ZeroMQ
  - fmt
  - "MySQL:(slc.*)"
  - bookkeeping-api
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Readout
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex
SONAME=so
case $ARCHITECTURE in
    osx*)
        SONAME=dylib
        [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
        [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
        [[ ! $LZ4_ROOT ]] && LZ4_ROOT=$(brew --prefix lz4)
        [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=$(brew --prefix zeromq)
        [[ ! $FMT_ROOT ]] && FMT_ROOT=`brew --prefix fmt`
    ;;
esac

cmake $SOURCEDIR                                                         \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                         \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR}          \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include}      \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      ${COMMON_O2_REVISION:+-DCommon_ROOT=$COMMON_O2_ROOT}                \
      ${MONITORING_REVISION:+-DMonitoring_ROOT=$MONITORING_ROOT}          \
      ${CONFIGURATION_REVISION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${READOUTCARD_REVISION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT}       \
      ${LIBINFOLOGGER_REVISION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT}    \
      ${FAIRMQ_REVISION:+-DFairMQ_DIR=$FAIRMQ_ROOT}                       \
      ${FAIRLOGGER_REVISION:+-DFairLogger_DIR=$FAIRLOGGER_ROOT}           \
      ${LZ4_ROOT:+-DLZ4_DIR=$LZ4_ROOT}                                   \
      ${CONTROL_OCCPLUGIN_REVISION:+-DOcc_ROOT=$CONTROL_OCCPLUGIN_ROOT}   \
      ${ZEROMQ_ROOT:+-DZMQ_ROOT=$ZEROMQ_ROOT}                             \
      ${BOOKKEEPING_API_REVISION:+-DBookkeepingApi_ROOT=$BOOKKEEPINGAPI_ROOT} \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                  \
      -DBUILD_SHARED_LIBS=ON

#build
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
set READOUT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv READOUT_ROOT \$READOUT_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
