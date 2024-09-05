package: json-c
version: "v0.17.0"
tag: "json-c-0.17-20230812"
source: https://github.com/json-c/json-c
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

mkdir build
cd build
../cmake-configure --disable-shared --enable-static --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS} install

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
