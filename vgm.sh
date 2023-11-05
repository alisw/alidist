package: vgm
version: "%(tag_basename)s"
tag: "v5-0"
source: https://github.com/vmc-project/vgm
requires:
  - ROOT
  - GEANT4
build_requires:
  - CMake
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*) SONAME=dylib ;;
  *) SONAME=so ;;
esac
cmake "$SOURCEDIR" \
  -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -DCMAKE_INSTALL_LIBDIR="lib"                 \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
  -DVDT_INCLUDE_DIR="$ROOT_ROOT/include"       \
  -DVDT_LIBRARY="$ROOT_ROOT/lib/libvdt.$SONAME"      \
  ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

make ${JOBS+-j $JOBS} install

# Relocation of .cmake files
for CMAKE in $(find "$INSTALLROOT/lib" -name '*.cmake'); do
  sed -ideleteme -e "s!$ROOTSYS!\$ENV{ROOTSYS}!g; s!$G4INSTALL!\$ENV{G4INSTALL}!g" "$CMAKE"
done
find "$INSTALLROOT/lib" -name '*deleteme' -delete || true

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
module load BASE/1.0 GEANT4/$GEANT4_VERSION-$GEANT4_REVISION ROOT/$ROOT_VERSION-$ROOT_REVISION
# Our environment
set VGM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VGM_ROOT \$VGM_ROOT
prepend-path LD_LIBRARY_PATH \$VGM_ROOT/lib
EoF
