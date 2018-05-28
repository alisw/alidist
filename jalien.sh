package: JAlien
version: "%(tag_basename)s"
tag: master
source: https://gitlab.cern.ch/jalien/jalien.git
build_requires:
 - Java
requires:
 - Java
 - JAlien-XRootD
---
#! /bin/bash -e

rsync -av $SOURCEDIR/ ./
./compile.sh users
rsync -av . $INSTALLROOT/

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
module load BASE/1.0 ${JAVA_ROOT:+Java/$JAVA_VERSION-$JAVA_REVISION} ${JALIEN_XROOTD_ROOT:+JAlien-XRootD/$JALIEN_XROOTD_VERSION-$JALIEN_XROOTD_REVISION}
# Our environment
setenv JALIEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JALIEN_ROOT)
prepend-path LD_LIBRARY_PATH \$::env(JALIEN_ROOT)/lib
EoF
