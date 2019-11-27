package: Geekbench
version: v3.4.1
source: https://gitlab.cern.ch/ALICEPrivateExternals/Geekbench.git
---
#!/bin/bash
if [[ ${ARCHITECTURE:0:3} == osx ]]; then
  echo "Geekbench is not provided for OSX via this recipe."
  exit 1
fi
mkdir -p "$INSTALLROOT/bin"
rsync -av "$SOURCEDIR/Linux/" "$INSTALLROOT/bin"
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
module load BASE/1.0
# Our environment
setenv GEEKBENCH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$GEEKBENCH_ROOT/bin
EoF
