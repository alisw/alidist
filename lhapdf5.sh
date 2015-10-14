package: lhapdf5
tag: alice/v5.9.1
version: "%(tag_basename)s"
source: https://github.com/alisw/LHAPDF
env:
  LHAPATH: "$LHAPDF5_ROOT/share/lhapdf"
---
#!/bin/bash -ex

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS} all
make install

PDFSETS="cteq6l cteq6ll EPS09LOR_208"
pushd $INSTALLROOT/share/lhapdf
  $INSTALLROOT/bin/lhapdf-getdata $PDFSETS
  # Check if PDF sets were really installed
  for P in $PDFSETS; do
    ls ${P}.*
  done
popd

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
setenv LHAPDF5_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPATH \$::env(LHAPDF5_ROOT)/share/lhapdf
prepend-path PATH $::env(LHAPDF5_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LHAPDF5_ROOT)/lib
EoF
