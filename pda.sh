package: PDA
version: "%(tag_basename)s"
tag: 12.0.0
source: https://github.com/AliceO2Group/pda.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - kernel-devel
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
--- 
#!/bin/sh

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./configure --debug=false --numa=true --modprobe=true --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS} install

#ModuleFile 
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root-env > "etc/modulefiles/$PKGNAME"
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
