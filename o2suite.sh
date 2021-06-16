package: O2Suite
version: "1.0.0"
tag: "O2Suite-1.0.0"
requires:
  - coconut
  - Control-Core
  - Control-OCCPlugin
  - O2
  - "ReadoutCard:(slc*)"
  - Readout
  - QualityControl
  - "DataDistribution:(?!osx)"
  - "ALF:(?!osx)"
  - "BookkeepingApiCpp:(slc*)"
  - "mesos:(slc8)"
build_requires:
  - alibuild-recipe-tools
valid_defaults:
  - o2
  - o2-dataflow
  - o2-dev-fairroot
  - alo
  - o2-prod
  - o2-ninja
---
#!/bin/bash -ex
# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
