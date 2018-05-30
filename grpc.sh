package: grpc
version: "%(tag_basename)s"
tag:  v1.9.1
requires:
  - protobuf
build_requires:
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/grpc/grpc
prefer_system: "(?!slc5)"
prefer_system_check: which grpc_cpp_plugin
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

rsync -a $SOURCEDIR/ ./

git submodule update --init # aie aie aie

# gRPC has a custom Makefile which readily breaks with some environment vars, better to run it in a clean environment
env -i HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" make ${JOBS:+-j$JOBS} prefix=$INSTALLROOT

# ldconfig won't work if we're not running make install as root, and that's ok, we don't need it
sed -i 's/ldconfig/true/' ./Makefile
make prefix=$INSTALLROOT install

MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
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
setenv GRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(GRPC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(GRPC_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
