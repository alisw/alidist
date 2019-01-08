package: qcg
version: "v1.4.2"
requires:
  - node
  - QualityControl
build_requires:
  - node
---
#!/bin/bash

mkdir -p "$INSTALLROOT/bin"
npm install @aliceo2/qc@$PKGVERSION --only=production --loglevel error --no-save --no-package-lock --prefix $INSTALLROOT
rsync -a --ignore-existing "$INSTALLROOT/node_modules/@aliceo2/qc/config-default.js" $INSTALLROOT/config.js
echo "node $INSTALLROOT/node_modules/@aliceo2/qc/index.js $INSTALLROOT/config.js" > $INSTALLROOT/bin/qcg
chmod +x $INSTALLROOT/bin/qcg

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
module load BASE/1.0 ${NODE_VERSION:+node/$NODE_VERSION-$NODE_REVISION} ${QUALITYCONTROL_VERSION:+QualityControl/$QUALITYCONTROL_VERSION-$QUALITYCONTROL_REVISION}
# Our environment
setenv QCG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(QCG_ROOT)/bin
EoF
