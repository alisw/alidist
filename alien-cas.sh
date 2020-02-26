package: AliEn-CAs
version: v1
tag: 53fbc54de2fc99129eff587ac0dd6dc814b0439e
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
