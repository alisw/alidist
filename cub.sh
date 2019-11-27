package: cub
version: "%(tag_basename)s"
tag: v1.8.0
source: https://github.com/NVlabs/cub.git
---
#!/bin/bash -e
rsync -a --delete --exclude='**/.git' --delete-excluded "$SOURCEDIR/" "$INSTALLROOT/"

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
set CUB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
