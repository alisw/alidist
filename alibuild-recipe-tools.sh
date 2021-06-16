package: alibuild-recipe-tools
version: "0.2.2"
tag: "v0.2.2"
source: https://github.com/alisw/alibuild-recipe-tools
---
install -D "$SOURCEDIR/alibuild-generate-module" "$INSTALLROOT/bin"

MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
"$INSTALLROOT/bin/alibuild-generate-module" --bin --lib > "$MODULEDIR/$PKGNAME"
