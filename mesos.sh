package: mesos
version: v1.11.0
tag: 1.11.0-alice1
source: https://github.com/AliceO2Group/mesos.git
requires:
  - zlib
  - glog
  - grpc
  - RapidJSON
  - system-apr
  - system-apr-util
  - system-cyrus-sasl
  - system-subversion
  # We specifically CANNOT build against our own curl and OpenSSL on slc8, as
  # those conflict with system-cyrus-sasl.
  # - curl
  # - OpenSSL
build_requires:
  - "autotools:(slc.*)"
  - protobuf
  - Python-modules
  - abseil
prepend_path:
  PATH: "$MESOS_ROOT/sbin"
  PYTHONPATH: $MESOS_ROOT/lib/python2.7/site-packages
---
export CXXFLAGS="-fPIC -O2 -std=c++14 -w"
# Needed for mesos grpc configure checks
export CPPFLAGS="-I${ABSEIL_ROOT}/include"
export CFLAGS="-I${ABSEIL_ROOT}/include"

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
make -j $((JOBS / 2))
make install


#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path PYTHONPATH \$PKG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
