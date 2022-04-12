package: O2DPG
version: "%(tag_basename)s"
tag: "TEST-IGNORE-epn-20220412-DDv1.3.9-flp-suite-v0.53.0"
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
