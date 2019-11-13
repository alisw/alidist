package: Readout
version: "%(tag_basename)s"
tag: v1.1.1
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - libInfoLogger
  - FairMQ
  - FairLogger
  - Monitoring
  - Configuration
  - ReadoutCard
  - lz4
  - Control-OCCPlugin
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Readout
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) 
	[[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
        [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl)
        [[ ! $LZ4_ROOT ]] && LZ4_ROOT=$(brew --prefix lz4)
    ;;
esac

# Enforce no warning code in the PR checker
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}                         \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR}          \
      ${COMMON_O2_VERSION:+-DCommon_ROOT=$COMMON_O2_ROOT}                \
      ${MONITORING_VERSION:+-DMonitoring_ROOT=$MONITORING_ROOT}          \
      ${CONFIGURATION_VERSION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${READOUTCARD_VERSION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT}       \
      ${LIBINFOLOGGER_VERSION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT}    \
      ${FAIRMQ_VERSION:+-DFairMQ_DIR=$FAIRMQ_ROOT}                       \
      ${FAIRLOGGER_VERSION:+-DFairLogger_DIR=$FAIRLOGGER_ROOT}           \
      ${PYTHON_VERSION:+-DPython3_ROOT_DIR="$PYTHON_ROOT"}               \
      ${LZ4_ROOT:+-DLZ4_DIR=$LZ4_ROOT}                                   \
      ${CONTROL_OCCPLUGIN_VERSION:+-DOcc_ROOT=$CONTROL_OCCPLUGIN_ROOT}   \
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
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            Monitoring/$MONITORING_VERSION-$MONITORING_REVISION               \\
            Configuration/$CONFIGURATION_VERSION-$CONFIGURATION_REVISION      \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION                  \\
            libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION      \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION            \\
            lz4/${LZ4_VERSION}-${LZ4_REVISION}                                \\
            FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION               \\
            FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION                           \\
            Control-OCCPlugin/$CONTROL_OCCPLUGIN_VERSION-$CONTROL_OCCPLUGIN_REVISION

# Our environment
setenv READOUT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(READOUT_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(READOUT_ROOT)/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
