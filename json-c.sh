package: json-c
version: "v0.13.1"
tag: "json-c-0.13.1-20180305"
source: https://github.com/json-c/json-c
build_requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
autoreconf -ivf
./configure --disable-shared --enable-static --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS} install
