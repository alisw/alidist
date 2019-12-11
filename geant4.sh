package: GEANT4
version: "%(tag_basename)s"
tag: "v10.4.2"
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
  G4INSTALL : $GEANT4_ROOT
  G4DATASEARCHOPT : "-mindepth 2 -maxdepth 4 -type d -wholename"
  G4LEDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*G4EMLOW*'`"
  G4LEVELGAMMADATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*PhotonEvaporation*'`"
  G4RADIOACTIVEDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*RadioactiveDecay*'`"
  G4NEUTRONHPDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*G4NDL*'`"
  G4NEUTRONXSDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*G4NEUTRONXS*'`"
  G4SAIDXSDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT  '*data*G4SAIDDATA*'`"
  G4PIIDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*G4PII*'`"
  G4REALSURFACEDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*RealSurface*'`"
  G4ENSDFSTATEDATA : "`find ${G4INSTALL} $G4DATASEARCHOPT '*data*G4ENSDFSTATE*'`"
---
#!/bin/bash -e

[[ $CXXSTD > 14 ]] && CXXSTD=14 || true  # Only C++14 is supported at the moment

# if this variable is not defined default it to OFF
: ${GEANT4_BUILD_MULTITHREADED:=OFF}

cmake $SOURCEDIR                                             \
  -DGEANT4_INSTALL_DATA_TIMEOUT=2000                         \
  -DCMAKE_CXX_FLAGS="-fPIC"                                  \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"                 \
  -DCMAKE_INSTALL_LIBDIR="lib"                               \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo                          \
  -DGEANT4_BUILD_TLS_MODEL:STRING="global-dynamic"           \
  -DGEANT4_ENABLE_TESTING=OFF                                \
  -DBUILD_SHARED_LIBS=ON                                     \
  -DGEANT4_INSTALL_EXAMPLES=OFF                              \
  -DCLHEP_ROOT_DIR:PATH="$CLHEP_ROOT"                        \
  -DGEANT4_BUILD_MULTITHREADED="$GEANT4_BUILD_MULTITHREADED" \
  -DCMAKE_STATIC_LIBRARY_CXX_FLAGS="-fPIC"                   \
  -DCMAKE_STATIC_LIBRARY_C_FLAGS="-fPIC"                     \
  -DGEANT4_USE_G3TOG4=ON                                     \
  -DGEANT4_INSTALL_DATA=ON                                   \
  -DGEANT4_USE_SYSTEM_EXPAT=OFF                              \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS}
make install

# auto discovery of installation paths of G4 DATA
# in order to avoid putting hard-coded version numbers (which change with every G4 tag)
# these variables are used to create the modulefile below
G4DATASEARCHOPT="-mindepth 2 -maxdepth 4 -type d -wholename"
G4LEDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4EMLOW*"`
G4LEVELGAMMADATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*PhotonEvaporation*"`
G4RADIOACTIVEDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*RadioactiveDecay*"`
G4NEUTRONHPDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4NDL*"`
G4NEUTRONXSDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4NEUTRONXS*"`
G4SAIDXSDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4SAIDDATA*"`
G4PIIDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4PII*"`
G4REALSURFACEDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*RealSurface*"`
G4ENSDFSTATEDATA=`find ${INSTALLROOT} $G4DATASEARCHOPT "*data*G4ENSDFSTATE*"`

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
set osname [uname sysname]
set GEANT4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv G4INSTALL \$::env(GEANT4_ROOT)
setenv G4INSTALL_DATA \$::env(G4INSTALL)/share/
setenv G4SYSTEM \$osname-g++
setenv G4LEVELGAMMADATA $G4LEVELGAMMADATA
setenv G4RADIOACTIVEDATA  $G4RADIOACTIVEDATA
setenv G4LEDATA $G4LEDATA
setenv G4NEUTRONHPDATA $G4NEUTRONHPDATA
setenv G4NEUTRONXSDATA $G4NEUTRONXSDATA
setenv G4SAIDXSDATA $G4SAIDXSDATA
setenv G4ENSDFSTATEDATA $G4ENSDFSTATEDATA
prepend-path PATH \$::env(GEANT4_ROOT)/bin
prepend-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include/Geant4
prepend-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include
prepend-path LD_LIBRARY_PATH \$::env(GEANT4_ROOT)/lib
EoF
