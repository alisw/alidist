package: FLUKA_VMC
version: "%(tag_basename)s"
tag: "4-1.1-vmc1"
source: https://gitlab.cern.ch/ALICEPrivateExternals/FLUKA_VMC.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
build_requires:
  - CMake
  - FLUKA
  - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root-env --extra > "$MODULEDIR/$PKGNAME" <<\EoF
setenv FLUVMC $PKG_ROOT
setenv FLUPRO $PKG_ROOT
setenv FLUKADATA $PKG_ROOT/data
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include/TFluka
EoF
