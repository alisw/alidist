package: O2DPG
version: "%(tag_basename)s"
tag: "nightly-20220301"
source: https://github.com/AliceO2Group/O2DPG.git
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
set O2DPG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2DPG_ROOT \$O2DPG_ROOT
setenv O2DPG_RELEASE \$version
setenv O2DPG_VERSION $PKGVERSION
EOF
