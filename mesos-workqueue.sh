package: mesos-workqueue
version: 0.0.2-%(short_hash)s
source: https://github.com/alisw/mesos-workqueue
tag: master
requires:
- mesos
- protobuf
- boost
- glog
build_requires:
- CMake
--- 
case $ARCHITECTURE in 
  osx*)
    [[ -z "$BOOST_ROOT" ]] && BOOST_ROOT=$(brew --prefix boost)
  ;;
esac
cmake "$SOURCEDIR"                               \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DPROTOBUF_ROOT=${PROTOBUF_ROOT}           \
      -DMESOS_ROOT=${MESOS_ROOT}                 \
      ${BOOST_ROOT:+-DBOOST_ROOT=${BOOST_ROOT}}  \
      -DGLOG_ROOT=${GLOG_ROOT}
make ${JOBS:+-j $JOBS}
make install
