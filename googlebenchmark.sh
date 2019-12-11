package: googlebenchmark
version: "1.3.0"
tag: v1.3.0
source: https://github.com/google/benchmark
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
---
#!/bin/bash -e
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}
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
set GOOGLEBENCHMARK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GOOGLEBENCHMARK_ROOT)/lib
EoF

