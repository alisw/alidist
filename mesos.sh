package: mesos
version: v1.11.0
tag: 1.11.0
source: https://git-wip-us.apache.org/repos/asf/mesos.git
requires:
- zlib
- "system-curl:(slc8)"
- "curl:(?!slc8)"
- OpenSSL
- glog
- grpc
- RapidJSON
- system-apr
- system-apr-util
- system-cyrus-sasl
- system-subversion
build_requires:
- "autotools:(slc6|slc7|slc8)"
- protobuf
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
    --with-glog=${GLOG_ROOT} \
    --with-rapidjson=${RAPIDJSON_ROOT}

# We build with fewer jobs to avoid OOM errors in GCC
make -j 4
make install


#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path PYTHONPATH \$PKG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
