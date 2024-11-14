package: AliGenO2
version: "v%(year)s%(month)s%(day)s"
requires:
  - DPMJET
  - POWHEG
  - pythia
  - SHERPA
  - ThePEG
  - Rivet
  - lhapdf-pdfsets
  - JETSCAPE
  - CRMC
  - EPOS4
  - STARlight
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -ex

# Modulefile
moduledir="$INSTALLROOT/etc/modulefiles"
mkdir -p "$moduledir"
alibuild-generate-module > "$moduledir/$PKGNAME"
