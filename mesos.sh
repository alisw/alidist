package: mesos
version: v1.11.0
tag: 1.11.0
source: https://git-wip-us.apache.org/repos/asf/mesos.git
requires:
- zlib
- "system-curl:(slc8)"
- "curl:(?!slc8)"
- OpenSSL
- grpc
build_requires:
- "autotools:(slc6|slc7|slc8)"
- system-apr
- system-apr-util
- system-cyrus-sasl
- protobuf
- glog
- Python-modules
prepend_path:
  PATH: "$MESOS_ROOT/sbin"
  PYTHONPATH: $MESOS_ROOT/lib/python2.7/site-packages
---
export CXXFLAGS="-fPIC -O2 -std=c++14 -w"
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
./bootstrap
mkdir build
cd build
../configure --prefix="$INSTALLROOT" \
    --disable-python \
    --disable-java \
    --with-protobuf=${PROTOBUF_ROOT} \
    --with-grpc=${GRPC_ROOT} \
    --with-glog=${GLOG_ROOT}

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
set MESOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MESOS_ROOT \$MESOS_ROOT
prepend-path PYTHONPATH \$MESOS_ROOT/lib/python2.7/site-packages
prepend-path LD_LIBRARY_PATH \$MESOS_ROOT/lib
prepend-path PATH \$MESOS_ROOT/bin
EoF

# External RPM dependencies
cat > $INSTALLROOT/.rpm-extra-deps <<EoF
cyrus-sasl
cyrus-sasl-md5
apr
apr-util
EoF
