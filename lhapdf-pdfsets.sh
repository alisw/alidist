package: lhapdf-pdfsets
version: "v%(year)s"
build_requires:
  - lhapdf
  - curl
---
#!/bin/bash -ex

PDFSETS="cteq6l1 MMHT2014lo68cl MMHT2014nlo68cl cteq66 CT10nlo CT14lo CT14nlo"
if [ ! -d $INSTALLROOT/share/LHAPDF ]; then mkdir -p $INSTALLROOT/share/LHAPDF; fi
pushd $INSTALLROOT/share/LHAPDF
  # REPO=https://lhapdf.hepforge.org/downloads?f=pdfsets/6.2.1
  REPO=http://lhapdfsets.web.cern.ch/lhapdfsets/current/ 
  for P in $PDFSETS; do
    PDFPACK=$(printf "%s.tar.gz" $P)
    PDFEXT=$(printf "%s/%s" $REPO $PDFPACK)
    curl -L $PDFEXT --output $PDFPACK
    tar xzvf $PDFPACK
    rm -rf $PDFPACK
  done
popd

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
module load BASE/1.0 ${LHAPDF_REVISION:+lhapdf/$LHAPDF_VERSION-$LHAPDF_REVISION}
# Our environment
set LHAPDF_PDFSETS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPDF_PDFSETS_ROOT \$LHAPDF_PDFSETS_ROOT
append-path LHAPDF_DATA_PATH \$::env(LHAPDF_PDFSETS_ROOT)/share/LHAPDF
EoF
