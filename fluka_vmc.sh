package: FLUKA_VMC
version: "%(tag_basename)s"
tag: "4-1.1-vmc5"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA_VMC.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
  - VMC
build_requires:
  - CMake
  - FLUKA
env:
  FLUVMC: "$FLUKA_VMC_ROOT"
  FLUPRO: "$FLUKA_VMC_ROOT"
prepend_path:
  LD_LIBRARY_PATH: "$FLUKA_VMC_ROOT/lib64"
  ROOT_INCLUDE_PATH: "$FLUKA_VMC_ROOT/include/TFluka"
---
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT      \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE     \
                 -DCMAKE_INSTALL_LIBDIR="lib"             \
                 ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}  \
                 -DCMAKE_SKIP_RPATH=TRUE                  \
                 -DFLUKA_ROOT=$FLUKA_ROOT                 \
                 -DFLUKAWITHDPMJET=TRUE
make ${JOBS:+-j $JOBS} install

[[ ! -d $INSTALLROOT/lib64 ]] && ln -sf lib $INSTALLROOT/lib64

rsync -av "$FLUKA_ROOT"/data "$INSTALLROOT/"

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
module load BASE/1.0 ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${VMC_REVISION:+VMC/$VMC_VERSION-$VMC_REVISION} ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set FLUKA_VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUKA_VMC_ROOT \$FLUKA_VMC_ROOT
setenv FLUVMC \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUKADATA \$::env(BASEDIR)/$PKGNAME/\$version/data
prepend-path LD_LIBRARY_PATH \$FLUKA_VMC_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$FLUKA_VMC_ROOT/include/TFluka
EoF
