package: O2sim
version: "async-2023-pp-apass3-20240219.1"
requires:
  - O2Physics
  - O2DPG
  - QualityControl
  - AEGIS
  - EVTGEN:(?!osx)
  - jq
---
#!/bin/bash -ex

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
