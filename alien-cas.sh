package: AliEn-CAs
version: v1
tag: bcb18b10f695dbfe85599b7bbb5452720a91dddd
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
