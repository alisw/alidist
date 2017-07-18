package: dim
version: "v20r20"
build_requires:
  - curl
  - "GCC-Toolchain:(?!osx)"
  - motif
---
#!/bin/bash -e

FILE_NAME="dim_$PKGVERSION"
ZIP_NAME="$FILE_NAME.zip"
URL="https://dim.web.cern.ch/dim/$ZIP_NAME"

curl -L -O $URL
unzip $ZIP_NAME
cd $FILE_NAME

# setup.sh is DOS-encoded
tr -d '\015' < setup.sh > setup2.sh
mv setup2.sh setup.sh

# Build (needs special environment)
( export OS=Linux
  source setup.sh
  gmake realclean
  gmake X64=yes )

# Installation
rsync -av dim/ $INSTALLROOT/dim/                # headers
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
setenv DIM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
