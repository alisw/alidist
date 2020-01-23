package: AliRoot-OCDB
version: "%(short_hash)s"
tag: master
source: https://gitlab.cern.ch/alisw/AliRootOCDB.git
---
#!/bin/bash -e
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ $INSTALLROOT/
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
set ALIROOT_OCDB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ALIROOT_OCDB_ROOT \$ALIROOT_OCDB_ROOT
EoF
