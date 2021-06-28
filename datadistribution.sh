package: DataDistribution
version: "%(tag_basename)s"
tag: v0.10.20
requires:
  - "GCC-Toolchain:(?!osx)"
  - boost
  - FairLogger
  - libInfoLogger
  - FairMQ
  - Ppconsul
  - grpc
  - Monitoring
  - protobuf
  - O2
  - fmt
build_requires:
  - CMake
source: https://github.com/AliceO2Group/DataDistribution
incremental_recipe: |
  # reduce number of compile slots if invoked  by Jenkins
  if [ ! "X$JENKINS_HOME" = X ]; then
    JOBS=4
  fi
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex


case $ARCHITECTURE in
    osx*)
        [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
        [[ ! $FMT_ROOT ]] && FMT_ROOT=$(brew --prefix fmt)
        [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=$(brew --prefix protobuf)
    ;;
esac

cmake $SOURCEDIR                                                \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                 \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
      ${BOOST_ROOT:+-DBoost_ROOT=$BOOST_ROOT}                   \
      ${FAIRLOGGER_ROOT:+-DFairLogger_ROOT=$FAIRLOGGER_ROOT}    \
      ${INFOLOGGER_ROOT:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT}    \
      ${FAIRMQ_ROOT:+-DFairMQ_ROOT=$FAIRMQ_ROOT}                \
      ${PPCONSUL_ROOT:+-Dppconsul_DIR=${PPCONSUL_ROOT}/cmake}   \
      ${O2_ROOT:+-DO2_ROOT=$O2_ROOT}                            \
      ${MONITORING_ROOT:+-DMonitoring_ROOT=$MONITORING_ROOT}    \
      ${PROTOBUF_ROOT:+-DProtobuf_ROOT=$PROTOBUF_ROOT}          \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
# reduce number of compile slots if invoked by Jenkins
if [ ! "X$JENKINS_HOME" = X ]; then
  JOBS=4
fi
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
module load BASE/1.0                                                                                \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}                                 \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${FAIRLOGGER_REVISION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION}             \\
            ${LIBINFOLOGGER_REVISION:+libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION} \\
            ${FAIRMQ_REVISION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION}                             \\
            ${PPCONSUL_REVISION:+Ppconsul/$PPCONSUL_VERSION-$PPCONSUL_REVISION}                     \\
            ${GRPC_REVISION:+grpc/$GRPC_VERSION-$GRPC_REVISION}                                     \\
            ${O2_REVISION:+O2/$O2_VERSION-$O2_REVISION}                                             \\
            ${MONITORING_REVISION:+Monitoring/$MONITORING_VERSION-$MONITORING_REVISION}             \\
            ${PROTOBUF_REVISION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}                     \\
            ${FMT_REVISION:+fmt/$FMT_VERSION-$FMT_REVISION}

# DataDistribution environment:
set DATADISTRIBUTION_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$DATADISTRIBUTION_ROOT/bin

# Not used for now:
# prepend-path LD_LIBRARY_PATH \$DATADISTRIBUTION_ROOT/lib
# prepend-path LD_LIBRARY_PATH \$DATADISTRIBUTION_ROOT/lib64
# prepend-path ROOT_INCLUDE_PATH \$DATADISTRIBUTION_ROOT/include

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
