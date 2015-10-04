package: MPFR
version: v3.1.3
source: https://github.com/alisw/MPFR.git
tag: v3.1.3
requires:
  - GMP
build_requires:
  - autotools
---
#!/bin/sh
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
autoreconf -ivf
case $ARCHITECTURE in
  osx*) CONFIG_OPTS="" ;;
  *x86-64) CONFIG_OPTS="--build=core2" ;;
  *) CONFIG_OPTS= ;;
esac

./configure --prefix=$INSTALLROOT \
            --disable-shared \
            --enable-static \
            --with-gmp=$GMP_ROOT \
            $CONFIG_OPTS

make ${JOBS+-j $JOBS}
make install

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
setenv MPFR_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(MPFR_ROOT)/lib
EoF
