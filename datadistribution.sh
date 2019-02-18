package: DataDistribution
version: "%(tag_basename)s"
tag: v0.5.1
requires:
  - boost
  - FairLogger
  - FairMQ
  - Monitoring
  - O2
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - ms_gsl
source: https://github.com/AliceO2Group/DataDistribution
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

cmake $SOURCEDIR                                              \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${FAIRLOGGER_ROOT:+-DFairLogger_ROOT=$FAIRLOGGER_ROOT}  \
      ${FAIRMQ_ROOT:+-DFairMQ_ROOT=$FAIRMQ_ROOT}              \
      ${O2_ROOT:+-DO2_ROOT=$O2_ROOT}                          \
      ${MONITORING_ROOT:+-DMonitoring_ROOT=$MONITORING_ROOT}  \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
cmake --build . -- ${JOBS+-j $JOBS} install

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
module load BASE/1.0                                                                              \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}                                \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}\\
            ${MONITORING_VERSION:+Monitoring/$MONITORING_VERSION-$MONITORING_REVISION}            \\
            ${FAIRLOGGER_VERSION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION}            \\
            ${FAIRMQ_VERSION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION}                            \\
            ${O2_VERSION:+O2/$O2_VERSION-$O2_REVISION}

# DataDistribution environment:
set DATADISTRIBUTION_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$DATADISTRIBUTION_ROOT/bin

# Not used for now:
# prepend-path LD_LIBRARY_PATH \$::env(DATADISTRIBUTION_ROOT)/lib
# prepend-path LD_LIBRARY_PATH \$::env(DATADISTRIBUTION_ROOT)/lib64
# prepend-path ROOT_INCLUDE_PATH \$::env(DATADISTRIBUTION_ROOT)/include

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
