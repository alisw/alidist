package: Control-Core
version: "%(tag_basename)s"
tag: "v1.26.0"
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - golang
  - protobuf
  - grpc
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Control
---
#!/bin/bash -e

clean_vendor() {
  go clean -modcache
}

export GOPATH=$PWD/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on
export GOCACHE=$BUILDDIR/cache
BUILD=$GOPATH/src/github.com/AliceO2Group/Control

# if something fails during build, we need to clean modules with go tools. Manually cleaning with rf
# results in problems with permissions.
trap clean_vendor ERR

mkdir -p $BUILD
rsync -a --delete $SOURCEDIR/ $BUILD/
pushd $BUILD
  make vendor
  make WHAT="o2-aliecs-core o2-aliecs-executor o2-apricot"
  mkdir -p $INSTALLROOT/bin
  rsync -a --delete bin/ $INSTALLROOT/bin
  # safely clean up vendor directory regardless of permissions
  clean_vendor
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
set CONTROL_CORE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$CONTROL_CORE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CONTROL_CORE_ROOT/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
