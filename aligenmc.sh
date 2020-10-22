package: aligenmc
version: "%(tag_basename)s"
tag: "v0.0.7-2"
source: https://github.com/alisw/aligenmc
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
set ALIGENMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ALIGENMC_ROOT \$ALIGENMC_ROOT
prepend-path PATH \$ALIGENMC_ROOT
EoF
