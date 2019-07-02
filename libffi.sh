package: libffi
version: v3.2.1
build_requires:
 - autotools
source: https://github.com/libffi/libffi
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
autoreconf -ivf .
./configure --prefix=$INSTALLROOT
make ${JOBS:+-j $JOBS}
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
module load BASE/1.0 $([[ $ALIEN_RUNTIME_VERSION ]] && echo "AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION" || echo "${ZLIB_VERSION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}")
# Our environment
set LIBPNG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$LIBFFI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LIBFFI_ROOT/lib
EoF
