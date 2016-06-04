package: mesos
version: v0.27.2
source: https://git-wip-us.apache.org/repos/asf/mesos.git
tag: 0.27.2
build_requires:
- autotools
- protobuf
- glog
- Python
prepend_path:
  PATH: "$MESOS_ROOT/sbin"
  PYTHONPATH: $MESOS_ROOT/lib/python2.7/site-packages
---

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
./bootstrap
mkdir build
cd build
../configure --prefix="$INSTALLROOT"         \
             --enable-python                 \
             --disable-java                  \
             --with-glog=${GLOG_ROOT}        \
             --with-protobuf=$PROTOBUF_ROOT
# We build with fewer jobs to avoid OOM errors in GCC
make -j 4
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
setenv MESOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$::env(MESOS_ROOT)/lib/python2.7/site-packages
prepend-path LD_LIBRARY_PATH \$::env(MESOS_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MESOS_ROOT)/lib")
prepend-path PATH \$::env(MESOS_ROOT)/bin
EoF
