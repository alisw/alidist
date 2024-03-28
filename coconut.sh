package: coconut
version: "%(tag_basename)s"
tag: "v1.8.0"
build_requires:
  - golang
  - protobuf
  - grpc
source: https://github.com/AliceO2Group/Control
---
#!/bin/bash -e

export GOPATH=$PWD/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on
export GOCACHE=$BUILDDIR/cache
BUILD=$GOPATH/src/github.com/AliceO2Group/Control
mkdir -p $BUILD
rsync -a --delete $SOURCEDIR/ $BUILD/
pushd $BUILD
  make vendor
  make WHAT="coconut peanut walnut"
  mkdir -p $INSTALLROOT/bin
  rsync -a --delete bin/ $INSTALLROOT/bin
  # safely clean up vendor directory regardless of permissions
  go clean -modcache
popd

#ModuleFile
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
module load BASE/1.0

# Our environment
set COCONUT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$COCONUT_ROOT/bin
prepend-path LD_LIBRARY_PATH \$COCONUT_ROOT/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
