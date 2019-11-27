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

#ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv MESOS_WORKQUEUE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$MESOS_WORKQUEUE_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$MESOS_WORKQUEUE_ROOT/lib")
prepend-path PATH \$MESOS_WORKQUEUE_ROOT/bin
EoF
