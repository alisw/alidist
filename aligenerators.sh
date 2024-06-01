package: AliGenerators
version: "v%(year)s%(month)s%(day)s"
tag: "vAN-20220930"
source: https://github.com/alisw/AliGenerators
requires:
  - AMPT
  - CRMC
  - DPMJET
  - EPOS
  - Herwig:(?!osx)
  - JEWEL
  - POWHEG
  - pythia
  - pythia6
  - SHERPA
  - ThePEG
  - AGILe:(?!osx)
  - Sacrifice
  - aligenmc
  - FONLL
  - Therminator2
  - Rivet
  - lhapdf-pdfsets
  - JETSCAPE
  - EPOS4
  - STARlight
build_requires:
  - EPOS-test:(?!osx)
  - alibuild-recipe-tools
---
#!/bin/bash -ex

# Modulefile
moduledir="$INSTALLROOT/etc/modulefiles"
mkdir -p "$moduledir"
alibuild-generate-module > "$moduledir/$PKGNAME"
