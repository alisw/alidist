package: grid-base-packages
version: v1
requires:
  - jq
---
#!/bin/bash -e
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
