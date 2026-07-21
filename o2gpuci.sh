package: O2GPUCI
version: "1.0.0"
tag: "O2GPUCI-1.0.0"
requires:
  - O2
  - O2-GPU-test:(.*x86-64)
  - O2-GPU-deterministic-test:(.*x86-64)
build_requires:
  - alibuild-recipe-tools
license: GPL-3.0
valid_defaults:
  - o2
  - o2-epn
  - ali
---
#!/bin/bash -ex

# Modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
