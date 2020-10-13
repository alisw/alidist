package: Control-Core
version: "%(tag_basename)s"
tag: "v0.17.1"
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - golang
  - protobuf
  - grpc
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
popd

mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 \\
            ${PROTOBUF_REVISION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}

# Our environment
set CONTROL_CORE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$CONTROL_CORE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CONTROL_CORE_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
