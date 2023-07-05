package: GEANT4
version: "%(tag_basename)s"
tag: "v11.0.4"
# source: https://github.com/alisw/geant4.git
source: https://gitlab.cern.ch/geant4/geant4.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - xercesc
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
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
  -DG4_USE_GDML=ON                                              \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON


make ${JOBS+-j $JOBS}
make install

# we should not use cached package links
packagecachefile=$(find ${INSTALLROOT} -name "Geant4PackageCache.cmake")
echo "#" > $packagecachefile

# Install data sets
# Can be done after Geant4 installation, if installed with -DGEANT4_INSTALL_DATA=OFF
# ./geant4-config --install-datasets

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set GEANT4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GEANT4_ROOT \$GEANT4_ROOT
EOF

# Data sets environment
$INSTALLROOT/bin/geant4-config --datasets |  sed 's/[^ ]* //' | sed 's/G4/setenv G4/' >> "$MODULEFILE"
