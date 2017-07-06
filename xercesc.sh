package: XercesC
version: v3.1.4
tag: v3.1.4
source: https://github.com/ShipSoft/XercesC
build_requires:
  - GCC-Toolchain:(?!osx)
env:
  XERCESC_INST_DIR: "$XERCESC_ROOT"
  XERCESCINST: "$XERCESC_ROOT"
  XERCESCROOT: "$XERCESC_ROOT"
---
#!/bin/sh

$SOURCEDIR/configure --prefix=$INSTALLROOT CFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS"
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
setenv XERCESC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv XERCESCROOT \$::env(XERCESC_ROOT)
setenv XERCESC_INST_DIR \$::env(XERCESC_ROOT)
setenv XERCESCINST \$::env(XERCESC_ROOT)
prepend-path PATH \$::env(XERCESC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(XERCESC_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(XERCESC_ROOT)/lib")
EoF
