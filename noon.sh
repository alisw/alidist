package: nOOn
version: "20250110"
tag: 2b5056c
requires:
  - ROOT
build_requires:
  - ROOT
  - alibuild-recipe-tools
source: https://github.com/mbroz84/noon.git
---
#!/bin/bash -e

# Copy code here
cp "$SOURCEDIR/NeutronGenerator.h" .
cp "$SOURCEDIR/NeutronGenerator.cxx" .

# Use CLING to build
root -l -b -q NeutronGenerator.cxx++g

# Install binary, scripts, and code
mkdir -p "$INSTALLROOT/lib"
mkdir -p "$INSTALLROOT/include"
cp "NeutronGenerator_cxx_ACLiC_dict_rdict.pcm"  "$INSTALLROOT/lib"
cp "NeutronGenerator_cxx.d" "$INSTALLROOT/lib"
cp "NeutronGenerator_cxx.so"  "$INSTALLROOT/lib/"
cp "$SOURCEDIR/NeutronGenerator.h"   "$INSTALLROOT/include/"
cp -r "$SOURCEDIR/Data"   "$INSTALLROOT/include/"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EOF
# extra environment
# we define this so that the starlight installation can be found/queried
setenv ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
# we purposely are not adding to ROOT_INCLUDE_PATH
# to avoid making that search path too long. Users can do
# this themselves in the ROOT macro (just-in-time) via ${PKGNAME}_ROOT.
# prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/
EOF
