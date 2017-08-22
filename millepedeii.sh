package: MillepedeII
version: V04-03-01
tag: V04-03-01
source: https://github.com/PMunkes/MillepedeII
---
#!/bin/bash
rsync -a $SOURCEDIR/* .

make  pede 
./pede -t
cp pede $INSTALLROOT/bin/

# Modulefile support
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
setenv MILLEPEDEII_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(MILLEPEDEII_ROOT)/bin
EoF
