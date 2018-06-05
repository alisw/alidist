package: Control
version: "%(commit_hash)s"
tag:  master
requires:
  - coconut
build_requires:
  - golang
  - protobuf
source: https://github.com/AliceO2Group/Control
incremental_recipe: |
  make WHAT="octld octl-executor" all
  mkdir -p $INSTALLROOT/bin
  cp bin/* $INSTALLROOT/bin
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

GOPATH=$PWD
PATH=$GOPATH/bin:$PATH
BUILD=$GOPATH/src/github.com/AliceO2Group/Control
mkdir -p $BUILD
rsync -a --delete $SOURCEDIR/ $BUILD/
cd $BUILD
make WHAT="octld octl-executor" all
mkdir -p $INSTALLROOT/bin
cp bin/* $INSTALLROOT/bin
cd -

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
            ${PROTOBUF_VERSION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}

# Our environment
set Control_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$Control_ROOT/bin
prepend-path LD_LIBRARY_PATH \$Control_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$Control_ROOT/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
