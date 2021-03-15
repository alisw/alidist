package: qcg
version: v1.10.3
tag: "@aliceo2/qc@1.10.3"
requires:
  - node
  - QualityControl
source: https://github.com/AliceO2Group/WebUi.git
valid_defaults:
  - o2
  - o2-dataflow
---
#!/bin/bash -e
npm install @aliceo2/qc@${PKGVERSION:1} --only=production --loglevel=verbose --no-save --no-package-lock --unsafe-perm --prefix ./

mkdir -p bin
cat > bin/qcg <<EOF
#!/bin/bash
exec node "$INSTALLROOT/node_modules/@aliceo2/qc/index.js" "$INSTALLROOT/node_modules/@aliceo2/qc/config.js"
EOF
chmod 0755 bin/qcg

# Installation
rsync -a --delete node_modules bin "$INSTALLROOT"

if [[ -e $INSTALLROOT/node_modules/@aliceo2/qc/config-default.js ]]; then
  mv -v "$INSTALLROOT/node_modules/@aliceo2/qc/config-default.js" "$INSTALLROOT/node_modules/@aliceo2/qc/config.js"
fi

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
module load BASE/1.0 ${NODE_REVISION:+node/$NODE_VERSION-$NODE_REVISION} ${QUALITYCONTROL_REVISION:+QualityControl/$QUALITYCONTROL_VERSION-$QUALITYCONTROL_REVISION}
# Our environment
set QCG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv QCG_ROOT \$QCG_ROOT
setenv NODE_PATH \$::env(BASEDIR)/$PKGNAME/\$version/node_modules
prepend-path PATH \$QCG_ROOT/bin
EoF
