package: sodium
version: v1.0.8
tag: 1.0.8
source: https://github.com/jedisct1/libsodium
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -i
./configure --prefix=$INSTALLROOT

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set SODIUM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SODIUM_ROOT \$SODIUM_ROOT
prepend-path LD_LIBRARY_PATH \$SODIUM_ROOT/lib
EoF
