package: Template-Recipe    # e.g. MyGenerator
version: "v1.0.0"
source: https://github.com/alisw/MyGenerator
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
---
#!/bin/bash -e

cmake  $SOURCEDIR                           \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

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
module load BASE/1.0
# Our environment
set MYGENERATOR_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MYGENERATOR_ROOT \$MYGENERATOR_ROOT
prepend-path PATH \$MYGENERATOR_ROOT/bin
prepend-path LD_LIBRARY_PATH \$MYGENERATOR_ROOT/lib
EoF
