package: libpng
version: v1.6.18
requires:
 - zlib
build_requires:
 - CMake
source: git://git.code.sf.net/p/libpng/code
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
cmake . \
    -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLROOT \
    -DBUILD_SHARED_LIBS=YES \
    -DZLIB_ROOT:PATH=$ZLIB_ROOT \
    -DCMAKE_SKIP_RPATH=YES \
    -DSKIP_INSTALL_FILES=1
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
module load BASE/1.0 zlib/$ZLIB_VERSION-$ZLIB_REVISION
# Our environment
setenv LIBPNG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(LIBPNG_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LIBPNG_ROOT)/lib
EoF
