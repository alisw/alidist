package: legotrain_helpers
version: "%(tag_basename)s"
tag: "v1.0.0"
source: https://github.com/mfasDa/legotrain_helpers
---
#!/bin/bash -e

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ $INSTALLROOT/

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
set LEGOTRAIN_HELPERS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LEGOTRAIN_HELPERS_ROOT \$LEGOTRAIN_HELPERS_ROOT
prepend-path PATH \$LEGOTRAIN_HELPERS_ROOT
EoF
