package: qcg
version: v1.5.0
tag: qcg-v1.5.0
requires:
  - node
  - QualityControl
source: https://github.com/AliceO2Group/WebUi.git
valid_defaults:
  - o2
  - o2-dataflow
---
#!/bin/bash -e

rsync -a --delete "$SOURCEDIR/QualityControl/" .

( unset PYTHONHOME PYTHONPATH PYTHONUSERBASE;
  major=$(python -c "import sys, __future__; print(sys.version_info.major);")
  if test $major != "2"; then
    # this hack is needed to ensure we have "python" = python2 for node-gyp
    # which is still not python3 compliant...
    ln -s $(which python2) $BUILDDIR/python
    export PATH=$BUILDDIR:$PATH 
  fi
  npm install --only=production --loglevel=verbose --no-save --no-package-lock --unsafe-perm)

mkdir -p bin
cat > bin/qcg <<EOF
#!/bin/bash
exec node "$INSTALLROOT/index.js" "$INSTALLROOT/config.js"
EOF
chmod 0755 bin/qcg

# Installation
rsync -a --delete bin lib node_modules public *.js *.node package.json \
                  "$INSTALLROOT"
if [[ -e $INSTALLROOT/config-default.js ]]; then
  mv -v "$INSTALLROOT/config-default.js" "$INSTALLROOT/config.js"
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
module load BASE/1.0 ${NODE_VERSION:+node/$NODE_VERSION-$NODE_REVISION} ${QUALITYCONTROL_VERSION:+QualityControl/$QUALITYCONTROL_VERSION-$QUALITYCONTROL_REVISION}
# Our environment
setenv QCG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(QCG_ROOT)/bin
EoF
