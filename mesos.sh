package: mesos
version: 0.25.0
source: https://git-wip-us.apache.org/repos/asf/mesos.git
build_requires:
- autotools
--- 

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
./bootstrap
mkdir build
cd build
../configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install
