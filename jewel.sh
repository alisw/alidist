package: JEWEL
version: v2.0.2
requires:
  - lhapdf5
---
#!/bin/bash -ex

ARCHIVE="jewel-2.0.2.tar.gz"
URL="https://www.hepforge.org/archive/jewel/${ARCHIVE}"

cd $SOURCEDIR
curl -O "${URL}"
tar xz -f ${ARCHIVE}

cd $BUILDDIR
rsync -a $SOURCEDIR/ $BUILDDIR/

sed -i -e 's#^LHAPDF_PATH :=.*#LHAPDF_PATH := ${LHAPDF5_ROOT}/lib#' Makefile

make

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
module load BASE/1.0
# Our environment
setenv JEWEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(JEWEL_ROOT)/bin
EoF
