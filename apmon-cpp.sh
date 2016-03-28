package: ApMon-CPP
version: "%(tag_basename)s"
tag: v2.2.8
source: https://github.com/alisw/apmon-cpp.git
build_requires:
 - autotools
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
autoreconf -ivf
./configure --prefix=$INSTALLROOT
make ${JOBS:+-j$JOBS}
make install
