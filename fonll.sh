package: FONLL
version: "1.3.3"
tag: "v1.3.3"
source: https://github.com/alisw/fonll.git
requires:
  - lhapdf
---
#!/bin/bash -ex

rsync -a $SOURCEDIR/ $BUILDDIR/
cd Linux && ./makefonlllha

mkdir -p $INSTALLROOT/bin
cp fonlllha $INSTALLROOT/bin

mkdir -p $INSTALLROOT/share
cp *.o $INSTALLROOT/share

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
module load BASE/1.0 lhapdf/${LHAPDF_VERSION}-${LHAPDF_REVISION}
# Our environment
setenv FONLL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(FONLL_ROOT)/bin
EoF
