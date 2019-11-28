package: ecsg
version: "v1.0.0"
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
  echo "[ -z \"\$1\" ] && CONFIG=\"$INSTALLROOT/config.js\" || CONFIG=\"\$1\"; node \"$INSTALLROOT/index.js\" \$CONFIG" > bin/ecsg
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
module load BASE/1.0 ${NODE_REVISION:+node/$NODE_VERSION-$NODE_REVISION}
# Our environment
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
EoF
