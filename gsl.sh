package: GSL
version: "v1.16"
---
#!/bin/bash -e
Url="ftp://ftp.gnu.org/gnu/gsl/gsl-${PKGVERSION}.tar.gz"
curl -o gsl.tar.gz "$Url"
tar xzf gsl.tar.gz
cd gsl-$PKGVERSION
./configure --prefix="$INSTALLROOT"
make -j$JOBS
make install -j$JOBS

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
setenv GSL_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GSL_BASEDIR)/lib
prepend-path PATH \$::env(GSL_BASEDIR)/bin
EoF
