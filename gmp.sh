package: GMP
version: v6.0.0
source: https://github.com/alisw/GMP.git
tag: v6.0.0
---
#!/bin/sh
case $ARCHITECTURE in
  osx*) BUILD="" ;;
  *x86-64) BUILD="core2" ;;
  *) BUILD= ;;
esac

$SOURCEDIR/configure --prefix=$INSTALLROOT \
            --enable-cxx                   \
            --enable-static                \
            --disable-shared               \
            ${BUILD:+--build=$BUILD}       \
            --with-pic

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
setenv GMP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GMP_ROOT)/lib
EoF
