package: protobuf
version: v2.5.0
source: https://github.com/google/protobuf
build_requires:
- autotools
--- 

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install
