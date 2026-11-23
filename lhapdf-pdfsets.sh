package: lhapdf-pdfsets
version: "v%(year)s"
license: GPL-3.0
build_requires:
  - lhapdf
  - curl
---
#!/bin/bash -ex

# NNPDF23 sets requested by MadGraph without the user naming them (it cannot download them at
# runtime on CVMFS): LHAPDF counterparts of its built-in pdlabels, used by systematics/PDF
# reweighting (nn23lo1=247000 LO default, nn23lo=246800, nn23nlo=244800) and the default lhaid
# for pdlabel=lhapdf (230000 at LO, 244600 at NLO).
PDFSETS="cteq6l1 MMHT2014lo68cl MMHT2014nlo68cl cteq66 CT10nlo CT14lo CT14nlo CT18NLO NNPDF23_lo_as_0130_qed NNPDF23_lo_as_0119_qed NNPDF23_nlo_as_0119_qed NNPDF23_nlo_as_0118_qed NNPDF23_nlo_as_0119"
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

# MadGraph looks up PDF sets only in the first LHAPDF_DATA_PATH entry that contains a
# pdfsets.index; if the set is not there it tries to download it (which fails on the read-only CVMFS).
# The index is shipped next to the sets and the directory is put first in LHAPDF_DATA_PATH in the modulefile.
cp "$LHAPDF_ROOT/share/LHAPDF/pdfsets.index" "$INSTALLROOT/share/LHAPDF/"

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
prepend-path LHAPDF_DATA_PATH \$::env(LHAPDF_PDFSETS_ROOT)/share/LHAPDF
EoF
