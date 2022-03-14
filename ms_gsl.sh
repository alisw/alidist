package: ms_gsl
version: "4.0.0"
tag: v4.0.0
source: https://github.com/Microsoft/GSL.git
prepend_path:
  ROOT_INCLUDE_PATH: "$MS_GSL_ROOT/include"
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

# recipe for the C++ guidelines support library (Microsoft implementation)
# can be deleted once we are fully C++17 compliant
cmake $SOURCEDIR                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT    \
      -DGSL_TEST=OFF                         \
      ${CXXSTD:+-DGSL_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS:+-j$JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set osname [uname sysname]
set MS_GSL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MS_GSL_ROOT \$MS_GSL_ROOT
prepend-path ROOT_INCLUDE_PATH \$MS_GSL_ROOT/include
EoF
