package: AliEn-CAs
version: v1
tag: f62625ede780d455b3b7878064bcfee6bd9a4f53
source: https://github.com/alisw/alien-cas.git
build_requires:
  - alibuild-recipe-tools
env:
  X509_CERT_DIR: "$ALIEN_CAS_ROOT/globus/share/certificates"
---
#!/bin/bash -e
DEST="$INSTALLROOT/globus/share/certificates"
mkdir -p "$DEST"
find "$SOURCEDIR" -type d -maxdepth 1 -mindepth 1 -exec rsync -av {}/ "$DEST" \;

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EOF
setenv X509_CERT_DIR \$::env(BASEDIR)/AliEn-CAs/\$version/globus/share/certificates
EOF
