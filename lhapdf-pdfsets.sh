package: lhapdf-pdfsets
version: "v%(year)s%(month)s%(day)s"
build_requires:
 - lhapdf
---
#!/bin/bash -ex

PDFSETS="cteq6l1 MMHT2014lo68cl MMHT2014nlo68cl cteq66"
lhapdf --pdfdir=$INSTALLROOT/share/LHAPDF  \
       --listdir=$LHAPDF_ROOT/share/LHAPDF \
       install $PDFSETS

# Check if PDF sets were really installed
for P in $PDFSETS; do
  [[ -d $INSTALLROOT/share/LHAPDF/$P ]]
done

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
module load BASE/1.0 ${LHAPDF_VERSION:+lhapdf/$LHAPDF_VERSION-$LHAPDF_REVISION}
# Our environment
setenv LHAPDF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPATH \$::env(LHAPDF_ROOT)/share/LHAPDF
EoF
