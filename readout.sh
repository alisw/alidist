package: Readout
version: "%(tag_basename)s"
tag: v0.13.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - InfoLogger
  - FairRoot
  - Monitoring
  - Configuration
  - ReadoutCard
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Readout
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}              \
      ${COMMON_O2_VERSION:+-DCommon_ROOT=$COMMON_O2_ROOT}     \
      ${MONITORING_VERSION:+-DMonitoring_ROOT=$MONITORING_ROOT} \
      ${CONFIGURATION_VERSION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${READOUTCARD_VERSION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT} \
      ${INFOLOGGER_VERSION:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT} \
      ${FAIRROOT_VERSION:+-DFAIRROOTPATH=$FAIRROOT_ROOT}      \
      ${FAIRROOT_VERSION:+-DFairRoot_DIR=$FAIRROOT_ROOT}      \
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
            InfoLogger/$INFOLOGGER_VERSION-$INFOLOGGER_REVISION               \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION            \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION

# Our environment
setenv READOUT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(READOUT_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(READOUT_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(READOUT_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
