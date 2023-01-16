package: GEANT4
version: "%(tag_basename)s"
tag: "v11.0.3"
# source: https://github.com/alisw/geant4.git
source: https://gitlab.cern.ch/geant4/geant4.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - "Xcode:(osx.*)"
prepend_path:
  ROOT_INCLUDE_PATH: "$GEANT4_ROOT/include:$GEANT4_ROOT/include/Geant4"
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
env:
  G4INSTALL: $GEANT4_ROOT
---
# If this variable is not defined default it to OFF
: ${GEANT4_BUILD_MULTITHREADED:=OFF}

# Data sets directory:
# if not set (default), data sets will be installed in CMAKE_INSTALL_DATAROOTDIR
: ${GEANT4_DATADIR:=""}

cmake $SOURCEDIR                                                \
  -DGEANT4_INSTALL_DATA_TIMEOUT=2000                            \
  -DCMAKE_CXX_FLAGS="-fPIC"                                     \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"                    \
  -DCMAKE_INSTALL_LIBDIR="lib"                                  \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo                             \
  -DGEANT4_BUILD_TLS_MODEL:STRING="global-dynamic"              \
  -DGEANT4_ENABLE_TESTING=OFF                                   \
  -DBUILD_SHARED_LIBS=ON                                        \
  -DGEANT4_INSTALL_EXAMPLES=OFF                                 \
  -DCLHEP_ROOT_DIR:PATH="$CLHEP_ROOT"                           \
  -DGEANT4_BUILD_MULTITHREADED="$GEANT4_BUILD_MULTITHREADED"    \
  -DCMAKE_STATIC_LIBRARY_CXX_FLAGS="-fPIC"                      \
  -DCMAKE_STATIC_LIBRARY_C_FLAGS="-fPIC"                        \
  -DGEANT4_USE_G3TOG4=ON                                        \
  -DGEANT4_INSTALL_DATA=ON                                      \
  ${GEANT4_DATADIR:+-DGEANT4_INSTALL_DATADIR="$GEANT4_DATADIR"} \
  -DGEANT4_USE_SYSTEM_EXPAT=OFF                                 \
  ${XERCESC_ROOT:+-DXERCESC_ROOT_DIR=$XERCESC_ROOT}             \
  ${CXXSTD:+-DGEANT4_BUILD_CXXSTD=$CXXSTD}                      \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS}
make install

# Install data sets
# Can be done after Geant4 installation, if installed with -DGEANT4_INSTALL_DATA=OFF
# ./geant4-config --install-datasets

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
module load BASE/1.0 ${XERCESC_REVISION:+xercesc/$XERCESC_REVISION-$XERCESC_REVISION}
# Our environment
set GEANT4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GEANT4_ROOT \$GEANT4_ROOT
prepend-path PATH \$GEANT4_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GEANT4_ROOT/lib
EoF

# Data sets environment
$INSTALLROOT/bin/geant4-config --datasets |  sed 's/[^ ]* //' | sed 's/G4/setenv G4/' >> "$MODULEFILE"
