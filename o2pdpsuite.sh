package: O2PDPSuite
version: "%(tag_basename)s"
tag: "epn-20261027-DDv1.6.11-QCv1.196.0-flp-suite-v1.86.0"
requires:
  # List important packages separately, even though they're also
  # pulled in by O2sim, so they show up in the dependency list on Monalisa.
  - O2
  - O2Physics
  - "DataDistribution:(?!osx|slc9_aarch64)"
  - QualityControl
  - O2DPG
  - O2sim
  - "ODC:(?!osx|slc9_aarch64)"
build_requires:
  - alibuild-recipe-tools
license: GPL-3.0
valid_defaults:
  - o2
  - o2-dataflow
  - o2-epn
  - ali
---
# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
