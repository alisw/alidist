package: HepMC3
version: "%(tag_basename)s"
tag: 3.3.1
source: https://gitlab.cern.ch/hepmc/HepMC3.git
requires:
  - GCC-Toolchain:(?!osx.*)
  - ROOT
license: GPL-3.0
build_requires:
  - CMake
prepend_path:
  ROOT_INCLUDE_PATH: "$HEPMC3_ROOT/include"
track_env:
  CMAKE_CXX_COMPILER_LAUNCHER: echo ${USE_RECC+recc}
  CMAKE_C_COMPILER_LAUNCHER: echo ${USE_RECC+recc}
---
#!/bin/bash -e

# Do not use RECC for link steps. On macOS, its command parser
# misinterprets valid @rpath/... install names as response files.
# Compilation can still use the compiler launcher normally.
cmake  $SOURCEDIR                          \
       -DROOT_DIR=$ROOT_ROOT               \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
       -DCMAKE_INSTALL_LIBDIR=lib          \
       -DCMAKE_C_LINKER_LAUNCHER=          \
       -DCMAKE_CXX_LINKER_LAUNCHER=        \
       -DHEPMC3_ENABLE_PYTHON=OFF          \
       -DHEPMC3_ENABLE_ROOTIO=ON

make ${JOBS+-j $JOBS}
make install

# HepMC3::rootIO exports ROOT_INCLUDE_DIRS as an absolute path.
# This makes the installed HepMC3 package non-relocatable and can leave
# references to the ROOT installation of the machine where HepMC3 was built.
#
# ROOT is already propagated through ROOT::Tree, ROOT::RIO and ROOT::Core,
# so the explicit absolute ROOT include directory is unnecessary.
# Locate the CMake import file installed for HepMC3's ROOT I/O target.
ROOTIO_TARGETS="$INSTALLROOT/share/HepMC3/cmake/HepMC3rootIOTargets.cmake"

# Remove the build machine's absolute ROOT include path from the exported target.
# Keep a backup temporarily so sed can edit the file in place safely.
sed -i.bak \
    "s#$ROOT_ROOT/include##g" \
    "$ROOTIO_TARGETS"

# Delete the temporary backup after the replacement succeeds.
rm -f "${ROOTIO_TARGETS}.bak"

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set HEPMC3_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HEPMC3_ROOT \$HEPMC3_ROOT
prepend-path PATH \$HEPMC3_ROOT/bin
prepend-path LD_LIBRARY_PATH \$HEPMC3_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$HEPMC3_ROOT/include
EoF
