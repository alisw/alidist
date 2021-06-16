package: O2FullCI
version: "1.0.0"
tag: "O2FullCI-1.0.0"
requires:
  - O2Suite
  - o2checkcode
  - O2-full-system-test
build_requires:
  - alibuild-recipe-tools
valid_defaults:
  - o2
---
#!/bin/bash -ex

# Modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
