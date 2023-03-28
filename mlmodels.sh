package: MLModels
version: "%(tag_basename)s"
tag: "20220530"
source: https://github.com/alisw/MLModels.git
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a $SOURCEDIR/models $INSTALLROOT/

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
setenv MLMODELS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
