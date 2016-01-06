package: FreeType
version: v2.6
requires:
 - AliEn-Runtime:(?!.*ppc64)
---
#!/bin/bash -ex
URL="http://download.savannah.gnu.org/releases/freetype/freetype-${PKGVERSION:1}.tar.gz"
curl -L -o freetype.tgz $URL
tar xzf freetype.tgz
rm -f freetype.tgz
cd freetype-${PKGVERSION:1}
./configure --prefix=$INSTALLROOT \
            --with-zlib=$ZLIB_ROOT
make ${JOBS:+-j$JOBS}
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
module load BASE/1.0 zlib/$ZLIB_VERSION-$ZLIB_REVISION
# Our environment
setenv FREETYPE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(FREETYPE_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(FREETYPE_ROOT)/lib
EoF
