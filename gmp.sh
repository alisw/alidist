package: GMP
version: v6.0.0
source: https://github.com/alisw/GMP.git
tag: v6.0.0
requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh
case $ARCHITECTURE in
  osx*) MARCH="" ;;
  *x86-64) MARCH="core2" ;;
  *) MARCH= ;;
esac

$SOURCEDIR/configure --prefix=$INSTALLROOT \
                     --enable-cxx \
                     --enable-static \
                     --disable-shared \
                     ${MARCH:+--build=$MARCH --host=$MARCH} \
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set GMP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$GMP_ROOT/lib
EoF
