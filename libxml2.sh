package: libxml2
version: "%(tag_basename)s"
source: https://github.com/GNOME/libxml2
tag: v2.9.4
requires:
  - zlib
build_requires:
  - "autotools"
  - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <libxml/parser.xaha>\n" | gcc -I`brew --prefix libxml2`/include/libxml2 -xc - -c -M 2>&1
---
#!/bin/sh

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./
autoreconf -ivf

./configure --disable-static --prefix=$INSTALLROOT --without-python --without-lzma

make ${JOBS+-j $JOBS}
make install
rm -rf $INSTALLROOT/lib/pkgconfig
rm -rf $INSTALLROOT/lib/*.{l,}a

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${ZLIB_ROOT:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}
# Our environment
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
