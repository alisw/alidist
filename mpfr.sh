package: MPFR
version: v3.1.3
tag: v3.1.3
source: https://github.com/alisw/MPFR.git
build_requires:
  - "autotools:(slc6|slc7)"
  - GMP
---
#!/bin/sh
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
perl -p -i -e 's/ doc / /' Makefile.am
autoreconf -ivf

./configure --prefix=$INSTALLROOT    \
            --disable-shared         \
            --enable-static          \
            --with-gmp=$GMP_ROOT     \
            --with-pic

make ${JOBS+-j $JOBS}
make install

rm -f $INSTALLROOT/lib/*.la

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
set MPFR_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MPFR_ROOT \$MPFR_ROOT
prepend-path LD_LIBRARY_PATH \$MPFR_ROOT/lib
EoF
