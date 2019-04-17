package: JAliEn
version: "%(tag_basename)s"
tag: "1.0.9"
source: https://gitlab.cern.ch/jalien/jalien.git
requires:
 - JDK
 - XRootD
valid_defaults:
 - jalien
---
#!/bin/bash -e

rsync -av $SOURCEDIR/ ./
./compile.sh users
mkdir -p $INSTALLROOT/{bin,lib}
cp alien-users.jar $INSTALLROOT/lib/
rsync -av bin/ $INSTALLROOT/bin/

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
module load BASE/1.0 JDK/$JDK_VERSION-$JDK_REVISION XRootD/$XROOTD_VERSION-$XROOTD_REVISION
# Our environment
set JALIEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path CLASSPATH \$JALIEN_ROOT/lib/alien-users.jar
prepend-path PATH \$JALIEN_ROOT/bin
EoF
