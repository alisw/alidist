# a pythia6 recipe based on the one from FairROOT
package: hijing
version: "%(tag_basename)s"
tag: "v1.36.1"
source: https://github.com/alisw/hijing.git
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
---
#!/bin/sh
cmake ${SOURCEDIR}                           \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}

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
module load BASE/1.0
# Our environment
set HIJING_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HIJING_ROOT \$HIJING_ROOT
prepend-path LD_LIBRARY_PATH \$HIJING_ROOT/lib
EoF

