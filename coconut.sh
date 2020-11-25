package: coconut
version: "%(tag_basename)s"
tag: "v0.18.2"
build_requires:
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
  make WHAT="coconut peanut walnut"
  mkdir -p $INSTALLROOT/bin
  rsync -a --delete bin/ $INSTALLROOT/bin
popd

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
