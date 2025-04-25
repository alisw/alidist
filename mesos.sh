package: mesos
version: v1.11.0
tag: 1.11.0-alice4
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
  - boost
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
export CXXFLAGS="-fPIC -O2 -std=c++20 -w"
export LIBS="-L${ABSEIL_ROOT}/lib -L${C_ARES_ROOT}/lib -L${RE2_ROOT}/lib -L${GRPC_ROOT}/lib -L${PROTOBUF_ROOT}/lib $(pkg-config --libs-only-l absl_log absl_cord absl_log_internal_check_op absl_raw_hash_set absl_status absl_flags protobuf libcares upb grpc_unsecure utf8_range) -laddress_sorting"
# Needed for mesos grpc configure checks
export CPPFLAGS="-I${ABSEIL_ROOT}/include"
export CFLAGS="-I${ABSEIL_ROOT}/include"

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
./bootstrap
mkdir build
cd build
sed -i.bak -e's/c++11/c++20/' ../configure
../configure --prefix="$INSTALLROOT" \
    --disable-python \
    --disable-java \
    --with-boost=${BOOST_ROOT} \
    --with-protobuf=${PROTOBUF_ROOT} \
    --with-re2=${RE2_ROOT} \
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
