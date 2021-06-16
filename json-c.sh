package: json-c
version: "v0.13.1"
tag: "json-c-0.13.1-20180305"
source: https://github.com/json-c/json-c
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
autoreconf -ivf
./configure --disable-shared --enable-static --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root-env > "etc/modulefiles/$PKGNAME"
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
