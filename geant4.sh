package: GEANT4
version: "%(tag_basename)s%(defaults_upper)s"
tag: v4.10.01.p03
source: https://github.com/alisw/geant4
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  G4INSTALL:                "$GEANT4_ROOT"
  G4INSTALL_DATA:           "$GEANT4_ROOT/share/Geant4-10.1.3"
  G4SYSTEM:                 "$(uname)-g++"
  G4LEVELGAMMADATA:         "$GEANT4_ROOT/share/Geant4-10.1.3/data/PhotonEvaporation3.1"
  G4RADIOACTIVEDATA:        "$GEANT4_ROOT/share/Geant4-10.1.3/data/RadioactiveDecay4.2"
  G4LEDATA:                 "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4EMLOW6.41"
  G4NEUTRONHPDATA:          "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4NDL4.5"
  G4NEUTRONXSDATA:          "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4NEUTRONXS1.4"
  G4SAIDXSDATA:             "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4SAIDDATA1.1"
  G4NeutronHPCrossSections: "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4NDL"
  G4PIIDATA:                "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4PII1.3"
  G4REALSURFACEDATA:        "$GEANT4_ROOT/share/Geant4-10.1.3/data/RealSurface1.0"
  G4ENSDFSTATEDATA:         "$GEANT4_ROOT/share/Geant4-10.1.3/data/G4ENSDFSTATE1.0"
---
#!/bin/bash -e

cmake $SOURCEDIR                                    \
  -DGEANT4_INSTALL_DATA_TIMEOUT=1500                \
  -DCMAKE_CXX_FLAGS="-fPIC"                         \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"        \
  -DCMAKE_INSTALL_LIBDIR="lib"                      \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo                 \
  -DGEANT4_BUILD_TLS_MODEL:STRING="global-dynamic"  \
  -DGEANT4_ENABLE_TESTING=OFF                       \
  -DBUILD_SHARED_LIBS=ON                            \
  -DGEANT4_INSTALL_EXAMPLES=OFF                     \
  -DCLHEP_ROOT_DIR:PATH="$CLHEP_ROOT"               \
  -DGEANT4_BUILD_MULTITHREADED=OFF                  \
  -DCMAKE_STATIC_LIBRARY_CXX_FLAGS="-fPIC"          \
  -DCMAKE_STATIC_LIBRARY_C_FLAGS="-fPIC"            \
  -DGEANT4_USE_G3TOG4=ON                            \
  -DGEANT4_INSTALL_DATA=ON                          \
  -DGEANT4_USE_SYSTEM_EXPAT=OFF                     \
  ${XERCESC_ROOT:+-DGEANT4_USE_OPENGL_X11=ON -DGEANT4_USE_GDML=ON -DXERCESC_ROOT_DIR=$XERCESC_ROOT}

make ${JOBS+-j $JOBS}
make install

ln -s lib $INSTALLROOT/lib64

#Get data file versions:
source $INSTALLROOT/bin/geant4.sh

G4LEVELGAMMADATA_NAME=$(basename "$G4LEVELGAMMADATA")
G4RADIOACTIVEDATA_NAME=$(basename "$G4RADIOACTIVEDATA")
G4LEDATA_NAME=$(basename "$G4LEDATA")
G4NEUTRONHPDATA_NAME=$(basename "$G4NEUTRONHPDATA")
G4NEUTRONXSDATA_NAME=$(basename "$G4NEUTRONXSDATA")
G4SAIDXSDATA_NAME=$(basename "$G4SAIDXSDATA")
G4NEUTRONXSDATA_NAME=$(basename "$G4NEUTRONXSDATA")
G4PIIDATA_NAME=$(basename "$G4PIIDATA")
G4REALSURFACEDATA_NAME=$(basename "$G4REALSURFACEDATA")
G4ENSDFSTATEDATA_NAME=$(basename "$G4ENSDFSTATEDATA")
G4ABLADATA_NAME=$(basename "$G4ABLADATA")
GEANT4_DATA_VERSION=$(dirname "$G4LEDATA")
GEANT4_DATA_VERSION=$(dirname "$GEANT4_DATA_VERSION")
GEANT4_DATA_VERSION=$(basename "$GEANT4_DATA_VERSION")

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
setenv GEANT4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv G4INSTALL \$::env(GEANT4_ROOT)
setenv G4INSTALL_DATA \$::env(GEANT4_ROOT)/share/$GEANT4_DATA_VERSION/data
setenv G4SYSTEM \$osname-g++
setenv G4LEVELGAMMADATA \$::env(G4INSTALL_DATA)/$G4LEVELGAMMADATA_NAME
setenv G4RADIOACTIVEDATA  \$::env(G4INSTALL_DATA)/$G4RADIOACTIVEDATA_NAME
setenv G4LEDATA \$::env(G4INSTALL_DATA)/$G4LEDATA_NAME
setenv G4NEUTRONHPDATA \$::env(G4INSTALL_DATA)/$G4NEUTRONHPDATA_NAME
setenv G4NEUTRONXSDATA \$::env(G4INSTALL_DATA)/$G4NEUTRONXSDATA_NAME
setenv G4SAIDXSDATA \$::env(G4INSTALL_DATA)/$G4SAIDXSDATA_NAME
setenv G4ABLADATA \$::env(G4INSTALL_DATA)/$G4ABLADATA_NAME
setenv G4PIIDATA \$::env(G4INSTALL_DATA)/G4PIIDATA_NAME
setenv G4REALSURFACEDATA \$::env(G4INSTALL_DATA)/$G4REALSURFACEDATA_NAME
setenv G4ENSDFSTATEDATA  \$::env(G4INSTALL_DATA)/$G4ENSDFSTATEDATA_NAME
prepend-path PATH \$::env(GEANT4_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(GEANT4_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(GEANT4_ROOT)/lib")
EoF
