package: GMP
version: v6.2.1
tag: v6.2.1
source: https://github.com/alisw/GMP.git
requires:
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root-env > "$MODULEDIR/$PKGNAME"
