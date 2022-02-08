package: googlebenchmark
version: "1.6.1"
tag: v1.6.1
source: https://github.com/google/benchmark
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - CMake
---
#!/bin/bash -e
cmake $SOURCEDIR                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
      -DBENCHMARK_ENABLE_GTEST_TESTS=OFF \
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
setenv GOOGLEBENCHMARK_ROOT \$GOOGLEBENCHMARK_ROOT
prepend-path LD_LIBRARY_PATH \$GOOGLEBENCHMARK_ROOT/lib
EoF

