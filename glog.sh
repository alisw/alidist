package: glog
version: v0.3.4
source: https://github.com/google/glog
build_requires:
 - autotools
 - "GCC-Toolchain:(?!osx)"
--- 
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install
