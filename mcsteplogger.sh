package: MCStepLogger
version: "%(tag_basename)s"
tag: "v0.6.1"
source: https://github.com/AliceO2Group/VMCStepLogger.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
  - VMC
  - boost
build_requires:
  - CMake
  - alibuild-recipe-tools
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT   \
          ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \
          -DROOT_DIR=${ROOT_ROOT}                      \
          -DBUILD_SHARED_LIBS=ON                       \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EoF
setenv MCSTEPLOGGER_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
