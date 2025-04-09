package: MPFR
version: v3.1.3
tag: v3.1.3
source: https://github.com/alisw/MPFR.git
build_requires:
  - "autotools:(slc6|slc7)"
  - GMP
  - alibuild-recipe-tools
---
#!/bin/sh
rsync -a --chmod=ug=rwX --delete --exclude .git --delete-excluded $SOURCEDIR/ .
sed -i.bak -e 's/ doc / /' Makefile.am
rm *.bak
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
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set MPFR_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MPFR_ROOT \$MPFR_ROOT
prepend-path LD_LIBRARY_PATH \$MPFR_ROOT/lib
EoF
