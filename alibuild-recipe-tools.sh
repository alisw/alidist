package: alibuild-recipe-tools
version: "0.2.5"
tag: "v0.2.5"
source: https://github.com/alisw/alibuild-recipe-tools
---
mkdir -p $INSTALLROOT/bin
install $SOURCEDIR/alibuild-generate-module $INSTALLROOT/bin

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
set ALIBUILD_RECIPE_TOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$ALIBUILD_RECIPE_TOOLS_ROOT/lib
prepend-path PATH \$ALIBUILD_RECIPE_TOOLS_ROOT/bin
EoF
