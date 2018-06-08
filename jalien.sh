package: JAlien
version: "%(tag_basename)s"
tag: master
source: https://gitlab.cern.ch/jalien/jalien.git
requires:
 - Java
 - XRootD
build_requires:
 - Java
valid_defaults:
 - jalien
---
#!/bin/bash -e

rsync -av $SOURCEDIR/ ./
./compile.sh users
mkdir -p $INSTALLROOT/lib
cp alien-users.jar $INSTALLROOT/lib/

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
module load BASE/1.0 ${JAVA_ROOT:+Java/$JAVA_VERSION-$JAVA_REVISION} ${XROOTD_ROOT:+XRootD/$XROOTD_VERSION-$XROOTD_REVISION}
# Our environment
set JALIEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path CLASSPATH \$JALIEN_ROOT/lib/alien-users.jar
EoF
