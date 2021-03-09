package: O2sim
version: "v%(year)s%(month)s%(day)s"
requires:
  - O2
  - O2DPG
  - AEGIS
---
#!/bin/bash -ex

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
