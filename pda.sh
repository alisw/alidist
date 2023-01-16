package: PDA
version: "%(tag_basename)s"
tag: 12.0.0
source: https://github.com/AliceO2Group/pda.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - kernel-devel
  - "autotools:(slc6|slc7)"
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./configure --debug=false --numa=true --modprobe=true --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS} install

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
module load BASE/1.0                                                                            \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}                       

# Our environment
set PDA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PDA_ROOT \$PDA_ROOT
set BASEDIR \$::env(BASEDIR)
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
