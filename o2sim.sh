package: O2sim
version: "v%(year)s%(month)s%(day)s"
requires:
  - O2
  - O2DPG
  - AEGIS
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -ex

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
