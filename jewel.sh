package: JEWEL
version: "%(tag_basename)s"
tag: v2.2.0
source: https://github.com/alisw/jewel.git
requires:
  - lhapdf5
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -ex
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
sed -i.deleteme -e 's#^LHAPDF_PATH :=.*#LHAPDF_PATH := ${LHAPDF5_ROOT}/lib#' Makefile

make ${JOBS:+-j$JOBS}

VERSION=${PKGVERSION%%_*}
VERSION=2.2.0
install -d ${INSTALLROOT}/bin
install -t ${INSTALLROOT}/bin \
	jewel-${VERSION#v}-vac \
	jewel-${VERSION#v}-simple

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
module load BASE/1.0 lhapdf5/$LHAPDF5_VERSION-$LHAPDF5_REVISION ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set JEWEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$JEWEL_ROOT/bin
EoF
