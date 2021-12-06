package: O2DataProcessing
version: "%(tag_basename)s"
tag: v0.23
source: https://github.com/AliceO2Group/O2DataProcessing.git
requires:
  - jq
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ $INSTALLROOT/

# Modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME

cat << EOF >> $INSTALLROOT/etc/modulefiles/$PKGNAME
set O2DATAPROCESSING_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2DATAPROCESSING_ROOT \$O2DATAPROCESSING_ROOT
EOF
