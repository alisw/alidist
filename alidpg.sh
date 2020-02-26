package: AliDPG
version: "%(tag_basename)s"
tag: master
source: https://github.com/alisw/AliDPG
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ $INSTALLROOT/

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv ALIDPG_RELEASE \$version
setenv ALIDPG_VERSION $PKGVERSION
set ALIDPG_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIDPG_RELEASE)
setenv ALIDPG_ROOT \$ALIDPG_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
