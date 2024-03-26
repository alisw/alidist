package: alibuild-variant-support
version: "0.1.0"
tag: "v0.1.0"
source: https://github.com/ktf/alibuild-variant-support
env:
  ALIBUILD_VARIANT_SUPPORT: "$ALIBUILD_VARIANT_SUPPORT_ROOT/bin/alibuild-variant-support"
tools:
  - bin/alibuild-variant-support
---
mkdir -p $INSTALLROOT/bin
install $SOURCEDIR/alibuild-variant-support $INSTALLROOT/bin

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
set ALIBUILD_VARIANT_SUPPORT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$ALIBUILD_VARIANT_SUPPORT_ROOT/lib
prepend-path PATH \$ALIBUILD_VARIANT_SUPPORT_ROOT/bin
EoF
