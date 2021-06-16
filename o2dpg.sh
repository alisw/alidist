package: O2DPG
version: "%(tag_basename)s"
tag: master
source: https://github.com/AliceO2Group/O2DPG.git
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ $INSTALLROOT/

# Modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module --root-env --extra > "$INSTALLROOT/etc/modulefiles/$PKGNAME" << EOF
setenv O2DPG_RELEASE \$version
setenv O2DPG_VERSION $PKGVERSION
EOF
