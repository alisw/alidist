package: Java
version: "10.0.1"
build_requires:
 - curl
---
#! /bin/bash -e
ZIP_NAME="jdk-10.0.1_linux-x64_bin.tar.gz"
UNZIP_NAME="jdk-10.0.1"
URL="http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/$ZIP_NAME"
curl -b "oraclelicense=a" -L -O $URL
tar xvfz $ZIP_NAME
rsync -av $UNZIP_NAME/* $INSTALLROOT/
export  PATH=$INSTALLROOT/Java/bin:$PATH

# Modulefile
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
setenv JAVA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JAVA_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JAVA_ROOT)/lib
EoF
