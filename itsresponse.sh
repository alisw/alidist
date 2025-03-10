package: ITSResponse
version: "%(tag_basename)s"
tag: v2.0.0
source: https://github.com/AliceO2Group/ITSChipResponseData.git
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

mkdir -p "$INSTALLROOT/response"
cp -r "$SOURCEDIR"/* "$INSTALLROOT/response"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ITSRESPONSE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ITSRESPONSE_ROOT \$ITSRESPONSE_ROOT
EoF
