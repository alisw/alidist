package: O2HLTCATracking
version: "%(tag_basename)s"
tag: hlt_o2_ca_tracking-v1.4
source: https://github.com/davidrohr/AliRoot
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
---
#!/bin/bash -e
cmake ${SOURCEDIR}/HLT/TPCLib/tracking-standalone/cmake_Standalone/ \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                          \
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
