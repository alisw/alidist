package: O2DPG
version: "%(tag_basename)s"
tag: "epn-20220704"
source: https://github.com/AliceO2Group/O2DPG.git
build_requires:
  - alibuild-recipe-tools
incremental_recipe: |
  rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ $INSTALLROOT/
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ $INSTALLROOT/

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin > etc/modulefiles/$PKGNAME
cat << EOF >> etc/modulefiles/$PKGNAME
set O2DPG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2DPG_ROOT \$O2DPG_ROOT
setenv O2DPG_RELEASE \$version
setenv O2DPG_VERSION $PKGVERSION
EOF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
