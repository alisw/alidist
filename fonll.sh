package: FONLL
version: "%(tag_basename)s"
tag: "v1.3.3-alice1"
source: https://github.com/alisw/fonll.git
requires:
  - lhapdf
  - "GCC-Toolchain:(?!osx)"
env:
  FONLL_NPDF: "$FONLL_ROOT/share/nPDF"
---
#!/bin/bash -ex

rsync -a --delete --exclude '**/.git' --exclude '**/nPDF' --delete-excluded $SOURCEDIR/ ./
pushd Linux
  ./makefonlllha
popd

mkdir -p $INSTALLROOT/bin $INSTALLROOT/share/nPDF
cp Linux/fonlllha $INSTALLROOT/bin

NPDF_EPPS16="EPPS16NLOR_208"
pushd $INSTALLROOT/share/nPDF
  for N in $NPDF_EPPS16; do
    curl -sfLO http://users.jyu.fi/~kaeskola/EPPS16/$N
    [[ -r $N ]]
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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
                     lhapdf/${LHAPDF_VERSION}-${LHAPDF_REVISION}
# Our environment
setenv FONLL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FONLL_NPDF \$::env(FONLL_ROOT)/share/nPDF
prepend-path PATH \$::env(FONLL_ROOT)/bin
EoF
