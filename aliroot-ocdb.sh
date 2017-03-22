package: AliRoot-OCDB
source: https://gitlab.cern.ch/alisw/AliRootOCDB.git
version: "%(short_hash)s"
tag: master
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
setenv ALIROOT_OCDB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
