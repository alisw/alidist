package: AliEn-WorkQueue
version: v1.3
source: https://github.com/alisw/alien-workqueue
requires:
  - "GCC-Toolchain:(?!osx)"
  - cctools
build_requires:
  - CMake
---
#!/bin/bash -e
cmake $SOURCEDIR                          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCCTOOLS=$CCTOOLS_ROOT
make ${JOBS+-j$JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} cctools/$CCTOOLS_VERSION-$CCTOOLS_REVISION
# Our environment
set ALIEN_WORKQUEUE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ALIEN_WORKQUEUE_ROOT \$ALIEN_WORKQUEUE_ROOT
prepend-path PATH \$ALIEN_WORKQUEUE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ALIEN_WORKQUEUE_ROOT/lib
EoF
