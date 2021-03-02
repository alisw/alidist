package: dim
version: "%(tag_basename)s"
tag: v20r26
source: https://github.com/alisw/dim
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
  - motif
  - system-curl
  - unzip
---
#!/bin/bash -e

#rsync -a $SOURCEDIR/ $BUILDDIR/
#cd $BUILDDIR

FILE_NAME="dim_$PKGVERSION"
ZIP_NAME="$FILE_NAME.zip"
URL="https://dim.web.cern.ch/dim/$ZIP_NAME"

curl -L -O $URL
unzip $ZIP_NAME
cd $FILE_NAME

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
rsync -av dim $INSTALLROOT/include                              # headers
rsync -av --exclude '*.o' --exclude '*.so' --exclude '*.a'  linux/ $INSTALLROOT/bin/  # executables
rsync -av linux/*.so linux/*.a $INSTALLROOT/lib/                # libraries
rsync -av --exclude "webDi*" WebDID/ $INSTALLROOT/WebDID/       #webdid without executables

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
