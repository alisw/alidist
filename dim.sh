package: dim
version: "v20r20"
build_requires:
  - curl
  - "GCC-Toolchain:(?!osx)"

---
#!/bin/bash -e

FILE_NAME="dim_$PKGVERSION"
ZIP_NAME="$FILE_NAME.zip"
URL="https://dim.web.cern.ch/dim/$ZIP_NAME"

curl -L -O $URL
unzip $ZIP_NAME
cd $FILE_NAME

# setup.sh is DOS encoded
tr -d '\015' <setup.sh >setup2.sh 
mv setup2.sh setup.sh

# compile
export OS=Linux
source setup.sh
gmake realclean
gmake X64=yes

# copy to destination
cp -r dim $INSTALLROOT
cp -r linux/* $INSTALLROOT  

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
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
