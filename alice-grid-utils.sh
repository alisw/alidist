package: Alice-GRID-Utils
version: "%(tag_basename)s"
tag: "0.0.8"
license: GPL-3.0
source: https://gitlab.cern.ch/jalien/alice-grid-utils.git
build_requires:
  - alibuild-recipe-tools
---
rsync -a --no-specials --no-devices  --chmod=ug=rwX --delete --delete-excluded $SOURCEDIR/ $INSTALLROOT/include/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --root > "$MODULEFILE"
