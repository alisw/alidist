package: AliEn-CAs
version: v1
tag: d04b129822b428a6acffaf1e5182b5c928f98174
source: https://github.com/alisw/alien-cas.git
---
#!/bin/bash -e
DEST="$INSTALLROOT/globus/share/certificates"
mkdir -p "$DEST"
for D in $SOURCEDIR/*; do
  [[ ! -d "$D" ]] && continue
  rsync -a "$D/" "$DEST/"
done

# No Modulefile is needed: the following line acknowledges it (and tests pass)
#%Module
