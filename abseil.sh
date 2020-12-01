package: abseil
version: "%(tag_basename)s"
tag:  20200225.2
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
source: https://github.com/abseil/abseil-cpp
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

mkdir -p $INSTALLROOT
cmake $SOURCEDIR                        \
  -DBUILD_TESTING=OFF                   \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS:+-j$JOBS} install


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
module load BASE/1.0                                                          \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set ABSEIL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$ABSEIL_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ABSEIL_ROOT/lib
EoF
