package: Control-Core
version: "%(tag_basename)s"
tag: "v0.19.0"
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - golang
  - protobuf
  - grpc
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Control
---
#!/bin/bash -e

export GOPATH=$PWD/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on
BUILD=$GOPATH/src/github.com/AliceO2Group/Control
mkdir -p $BUILD
rsync -a --delete $SOURCEDIR/ $BUILD/
pushd $BUILD
  make vendor
  make WHAT="o2control-core o2control-executor o2-aliecs-odc-shim"
  mkdir -p $INSTALLROOT/bin
  rsync -a --delete bin/ $INSTALLROOT/bin
  # safely clean up vendor directory regardless of permissions
  go clean -modcache
popd

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
