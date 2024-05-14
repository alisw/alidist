package: mesos-dds
version: master
tag: master
source: https://github.com/alisw/mesos-dds
requires:
  - mesos
  - protobuf
  - boost
  - glog
  - cpprestsdk
  - DDS
build_requires:
  - CMake
---
#!/bin/sh

case $ARCHITECTURE in
  osx*)
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    [[ ! $MESOS_ROOT ]] && MESOS_ROOT=$(brew --prefix mesos)
  ;;
esac

cmake "$SOURCEDIR"                               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DPROTOBUF_ROOT=${PROTOBUF_ROOT}           \
      ${MESOS_ROOT:+-DMESOS_ROOT=${MESOS_ROOT}}  \
      ${BOOST_ROOT:+-DBOOST_ROOT=${BOOST_ROOT}}  \
      -DGLOG_ROOT=${GLOG_ROOT}                   \
      -DCPPRESTSDK_ROOT=${CPPRESTSDK_ROOT}       \
      -DDDS_ROOT=${DDS_ROOT}

make ${JOBS:+-j $JOBS}
make install

