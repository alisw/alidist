package: qcg
version: "v1.0.4"
requires:
  - node
build_requires:
  - node
---
#!/bin/bash

cd "$INSTALLROOT"
npm install @aliceo2/qc@$PKGVERSION --only=production --loglevel error --no-save --no-package-lock
cp "node_modules/@aliceo2/qc/config-default.js" config.js
mkdir bin;
echo "node $INSTALLROOT/node_modules/@aliceo2/qc/index.js $INSTALLROOT/config.js" > bin/qcg
chmod +x bin/qcg

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
setenv QCG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(QCG_ROOT)/bin
EoF
