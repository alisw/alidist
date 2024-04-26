package: Control
version: "v1.8.3"
requires:
  - Control-Core
  - Control-OCCPlugin
  - coconut
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
