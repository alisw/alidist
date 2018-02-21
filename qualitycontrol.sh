package: QualityControl
version: "%(tag_basename)s"
tag: v0.3.1
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - InfoLogger
  - FairRoot
  - DataSampling
  - Monitoring
  - Configuration
  - O2
build_requires:
  - CMake
source: https://github.com/AliceO2Group/QualityControl
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
      ${DATASAMPLING_VERSION:+-DDataSampling_ROOT=$DATASAMPLING_ROOT} \
      ${MONITORING_VERSION:+-DMonitoring_ROOT=$MONITORING_ROOT} \
      ${CONFIGURATION_VERSION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${INFOLOGGER_VERSION:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT} \
      ${O2_VERSION:+-DO2_ROOT=$O2_ROOT}                       \
      ${FAIRROOT_VERSION:+-DFAIRROOTPATH=$FAIRROOT_ROOT}      \
      ${FAIRROOT_VERSION:+-DFairRoot_DIR=$FAIRROOT_ROOT}      \
      -DMS_GSL_INCLUDE_DIR=$MS_GSL_ROOT/include               \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
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
            DataSampling/$DATASAMPLING_VERSION-$DATASAMPLING_REVISION         \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION                     \\
            O2/$O2_VERSION-$O2_REVISION

# Our environment
setenv QUALITYCONTROL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(QUALITYCONTROL_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
