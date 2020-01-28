package: AliEn-CAs
version: v1
tag: 4a5bccfccd2c32cc32eb53ae44e213d19b536d2d
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
