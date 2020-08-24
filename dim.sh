package: dim
version: "%(tag_basename)s"
tag: v20r26
source: https://github.com/alisw/dim
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - motif
---
#!/bin/bash -e

rsync -a $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR

# setup.sh is DOS-encoded
tr -d '\015' < setup.sh > setup2.sh
mv setup2.sh setup.sh

# DIM installation needs `gmake` (`make` is not sufficient)
mkdir buildbin
export PATH="$PWD/buildbin:$PATH"
ln -nfs $(which make) buildbin/gmake

# Build (needs special environment)
( export OS=Linux
  source setup.sh
  gmake realclean
  gmake X64=yes )

# Installation
rsync -av dim/ $INSTALLROOT/dim/                # headers
rsync -av --exclude "webDi*" WebDID/ $INSTALLROOT/WebDID/ #webdid without executables
rsync -av --exclude "*.o" linux/ $INSTALLROOT/  # executables and libraries

# Modulefile
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set DIM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv DIM_ROOT \$DIM_ROOT
set BASEDIR \$::env(BASEDIR)
prepend-path PATH \$BASEDIR/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
