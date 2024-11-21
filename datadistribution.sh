package: DataDistribution
version: "%(tag_basename)s"
tag: v1.6.5
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
  # reduce number of compile slots if invoked by Jenkins
  if [ ! "X$JENKINS_HOME" = X ]; then
    JOBS=4
  fi
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
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
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
      ${BOOST_ROOT:+-DBoost_ROOT=$BOOST_ROOT}                   \
      ${FAIRLOGGER_ROOT:+-DFairLogger_ROOT=$FAIRLOGGER_ROOT}    \
      ${INFOLOGGER_ROOT:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT}    \
      ${FAIRMQ_ROOT:+-DFairMQ_ROOT=$FAIRMQ_ROOT}                \
      ${PPCONSUL_ROOT:+-Dppconsul_DIR=${PPCONSUL_ROOT}/cmake}   \
      ${O2_ROOT:+-DO2_ROOT=$O2_ROOT}                            \
      ${MONITORING_ROOT:+-DMonitoring_ROOT=$MONITORING_ROOT}    \
      ${PROTOBUF_ROOT:+-DProtobuf_ROOT=$PROTOBUF_ROOT}          \
      ${UCX_ROOT:+-DUCX_DIR=${UCX_ROOT}}                        \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
# reduce number of compile slots if invoked by Jenkins
if [ ! "X$JENKINS_HOME" = X ]; then
  JOBS=4
fi
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
