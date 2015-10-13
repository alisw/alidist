package: JEWEL
version: "%(tag_basename)s"
tag: alice/v2.0.2
source: https://github.com/alisw/jewel.git
requires:
  - lhapdf5
---
#!/bin/bash -ex
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
sed -i.deleteme -e 's#^LHAPDF_PATH :=.*#LHAPDF_PATH := ${LHAPDF5_ROOT}/lib#' Makefile

make ${JOBS:+-j$JOBS}

install -d ${INSTALLROOT}/bin
install -t ${INSTALLROOT}/bin \
	jewel-${PKGVERSION#v}-vac \
	jewel-${PKGVERSION#v}-simple

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
module load BASE/1.0 lhapdf5/$LHAPDF5_VERSION-$LHAPDF5_REVISION
# Our environment
setenv JEWEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(JEWEL_ROOT)/bin
EoF
