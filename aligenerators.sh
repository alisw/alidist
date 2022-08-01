package: AliGenerators
version: "v%(year)s%(month)s%(day)s"
tag: "vAN-20220727"
source: https://github.com/alisw/AliGenerators
requires:
  - AMPT
  - CRMC:(?!osx)
  - DPMJET
  - EPOS:(?!osx)
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
build_requires:
  - EPOS-test:(?!osx)
  - alibuild-recipe-tools
---
#!/bin/bash -ex

# Modulefile
moduledir="$INSTALLROOT/etc/modulefiles"
mkdir -p "$moduledir"
alibuild-generate-module > "$moduledir/$PKGNAME"
