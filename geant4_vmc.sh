package: GEANT4_VMC
version: "%(tag_basename)s"
tag: "v5-3"
source: https://github.com/vmc-project/geant4_vmc
requires:
  - ROOT
  - GEANT4
  - vgm
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$GEANT4_VMC_ROOT/include/g4root:$GEANT4_VMC_ROOT/include/geant4vmc:$GEANT4_VMC_ROOT/include/mtroot"
env:
  G4VMCINSTALL: "$GEANT4_VMC_ROOT"
---
#!/bin/bash -e
LDFLAGS="$LDFLAGS -L$GEANT4_ROOT/lib"            \
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DGeant4VMC_USE_VGM=ON                       \
    -DCMAKE_INSTALL_LIBDIR=lib                   \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

make ${JOBS+-j $JOBS} install
G4VMC_SHARE=$(cd "$INSTALLROOT/share"; echo Geant4VMC-* | cut -d' ' -f1)
ln -nfs "$G4VMC_SHARE/examples" "$INSTALLROOT/share/examples"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env --extra > "$MODULEDIR/$PKGNAME" <<\EoF
setenv G4VMCINSTALL $PKG_ROOT
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include/mtroot
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include/geant4vmc
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include/g4root
EoF
