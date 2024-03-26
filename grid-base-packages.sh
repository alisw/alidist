package: grid-base-packages
version: v1
requires:
  - jq
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
