package: O2PDPSuite
version: "%(tag_basename)s"
tag: "daily-20250623-0000"
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
