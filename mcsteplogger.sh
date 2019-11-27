package: MCStepLogger
version: "%(tag_basename)s"
tag: master
source: https://github.com/AliceO2Group/VMCStepLogger.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - ROOT
  - boost
build_requires:
  - CMake
---

#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT   \
          ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \
          -DROOT_DIR=${ROOT_ROOT}                      \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

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
module load BASE/1.0 ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set osname [uname sysname]
setenv MCSTEPLOGGER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$MCSTEPLOGGER_ROOT/lib
prepend-path PATH \$MCSTEPLOGGER_ROOT/bin
prepend-path ROOT_INCLUDE_PATH \$MCSTEPLOGGER_ROOT/include
EoF
