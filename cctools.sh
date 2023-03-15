package: cctools
version: v5.4.17-alice2
source: https://github.com/alisw/cctools
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - zlib
  - SWIG
---
#!/bin/bash
rsync -a --delete --exclude "**/.git" $SOURCEDIR/ .
[[ "$ZLIB_ROOT" == '' ]] || cp -v $ZLIB_ROOT/lib/libz.a .
./configure --prefix=$INSTALLROOT                     \
            ${SWIG_ROOT:+--with-swig-path=$SWIG_ROOT} \
            ${ZLIB_ROOT:+--with-zlib-path=$PWD}
make ${JOBS+-j$JOBS}
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set CCTOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv CCTOOLS_ROOT \$CCTOOLS_ROOT
prepend-path PATH \$CCTOOLS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CCTOOLS_ROOT/lib
EoF
