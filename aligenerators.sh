package: AliGenerators
version: "v%(year)s%(month)s%(day)s"
requires:
  - CRMC
  - EPOS
  - JEWEL
  - POWHEG
  - pythia
  - pythia6
  - SHERPA
  - ThePEG
build_requires:
  - EPOS-test
  - ThePEG-test
---
#!/bin/bash -ex

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
module load BASE/1.0 \
  CRMC/$CRMC_VERSION-$CRMC_REVISION \
  JEWEL/$JEWEL_VERSION-$JEWEL_REVISION \
  POWHEG/$POWHEG_VERSION-$POWHEG_REVISION \
  pythia/$PYTHIA_VERSION-$PYTHIA_REVISION \
  pythia6/$PYTHIA6_VERSION-$PYTHIA6_REVISION \
  SHERPA/$SHERPA_VERSION-$SHERPA_REVISION \
  ThePEG/$THEPEG_VERSION-$THEPEG_REVISION
EoF
