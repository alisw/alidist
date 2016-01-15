package: mesos
version: v0.25.0
source: https://git-wip-us.apache.org/repos/asf/mesos.git
tag: 0.25.0
build_requires:
- autotools
- protobuf
- glog
--- 

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
./bootstrap
mkdir build
cd build
../configure --prefix="$INSTALLROOT"         \
             --disable-python                \
             --disable-java                  \
             --with-glog=${GLOG_ROOT}        \
             --with-protobuf=$PROTOBUF_ROOT
# We build with fewer jobs to avoid OOM errors in GCC
make -j 4
make install
