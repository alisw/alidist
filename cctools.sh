package: cctools
version: v5.3.1
source: https://github.com/cooperative-computing-lab/cctools
tag: 18a15be6bbe1a60c9f89f8ff58530366c4bf6663
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
 - zlib
 - SWIG
---
#!/bin/bash
rsync -a --delete --exclude "**/.git" $SOURCEDIR/ .
[[ "$ZLIB_ROOT" == '' ]] || cp -v $ZLIB_ROOT/lib/libz.a .
./configure --prefix=$INSTALLROOT \
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
setenv CCTOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CCTOOLS_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(CCTOOLS_ROOT)/lib
EoF
