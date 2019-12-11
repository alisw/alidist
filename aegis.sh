package: AEGIS
version: "%(tag_basename)s"
tag: v1.0
requires:
  - ROOT
  - pythia6
build_requires:
  - CMake
  - "Xcode:(osx.*)"
source: https://github.com/AliceO2Group/AEGIS.git
prepend_path:
  LD_LIBRARY_PATH: "$AEGIS_ROOT/lib"
  ROOT_INCLUDE_PATH: "$AEGIS_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION 
# Our environment
set AEGIS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(AEGIS_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(AEGIS_ROOT)/include
EoF
