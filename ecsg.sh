package: ecsg
version: "%(tag_basename)s"
tag: qcg-v1.4.4
requires:
  - node
build_requires:
  - node
source: https://github.com/AliceO2Group/WebUi.git
---
#!/bin/bash

rsync -a --delete  $SOURCEDIR/Control/* $BUILDDIR/
pushd $BUILDDIR
  npm install --only=production --loglevel error --no-save --no-package-lock
  mkdir -p bin
  echo "node $INSTALLROOT/index.js $INSTALLROOT/config.js" > bin/ecsg
  chmod +x bin/ecsg
popd

rsync -a --delete $BUILDDIR/ $INSTALLROOT/
rsync -a --ignore-existing $BUILDDIR/config-default.js $INSTALLROOT/config.js

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${NODE_VERSION:+node/$NODE_VERSION-$NODE_REVISION}
# Our environment
setenv ECG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(ECG_ROOT)/bin
EoF
