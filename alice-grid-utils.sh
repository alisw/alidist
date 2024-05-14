package: Alice-GRID-Utils
version: "%(tag_basename)s"
tag: "0.0.7"
source: https://gitlab.cern.ch/jalien/alice-grid-utils.git
---
#!/bin/bash -e

DST="$INSTALLROOT/include"
mkdir -p "$DST"
cp -v "$SOURCEDIR"/*.h "$DST/"

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
EoF
