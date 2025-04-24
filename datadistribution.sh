package: DataDistribution
version: "%(tag_basename)s"
tag: v1.6.9
source: https://github.com/AliceO2Group/DataDistribution
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
      -DCMAKE_CXX_STANDARD=20                                   \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
      ${BOOST_ROOT:+-DBoost_ROOT=$BOOST_ROOT}                   \
      ${FAIRLOGGER_ROOT:+-DFairLogger_ROOT=$FAIRLOGGER_ROOT}    \
      ${INFOLOGGER_ROOT:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT}    \
      ${FAIRMQ_ROOT:+-DFairMQ_ROOT=$FAIRMQ_ROOT}                \
      ${PPCONSUL_ROOT:+-Dppconsul_DIR=${PPCONSUL_ROOT}/cmake}   \
      ${O2_ROOT:+-DO2_ROOT=$O2_ROOT}                            \
      -Dprotobuf_MODULE_COMPATIBLE=ON                           \
      ${MONITORING_ROOT:+-DMonitoring_ROOT=$MONITORING_ROOT}    \
      ${PROTOBUF_ROOT:+-DProtobuf_ROOT=$PROTOBUF_ROOT}          \
      ${UCX_ROOT:+-DUCX_DIR=${UCX_ROOT}}                        \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
# This really means we are in development mode. We need to make sure we
# use the real path for sources in this case. We also copy the
# compile_commands.json file so that IDEs can make use of it directly, this
# is a departure from our "no changes in sourcecode" policy, but for a good reason
# and in any case the file is in gitignore.
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# reduce number of compile slots if invoked by Jenkins
if [ ! "X$JENKINS_HOME" = X ]; then
  JOBS=4
fi
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
