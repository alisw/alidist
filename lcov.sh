package: lcov
version: v1.13
tag: v1.13
source: https://github.com/linux-test-project/lcov.git
env:
  CMAKE_BUILD_TYPE: COVERAGE
---
#!/bin/sh
rsync -av $SOURCEDIR/ $BUILDDIR/
make ${JOBS+-j $JOBS}
make PREFIX=$INSTALLROOT BIN_DIR=$INSTALLROOT/bin install

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
set LCOV_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LCOV_ROOT \$LCOV_ROOT
prepend-path LD_LIBRARY_PATH \$LCOV_ROOT/lib
EoF

