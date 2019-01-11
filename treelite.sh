package: treelite
version: "%(tag_basename)s"
tag: "2a12742269c1d3de553d9a12ff36bc2a5d874239"
source: https://github.com/dmlc/treelite
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - "Xcode:(osx.*)"
---
#!/bin/bash -e

rsync -a $SOURCEDIR/ src/
pushd src
  git submodule update --init --recursive
popd

cmake src                                   \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"

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
module load BASE/1.0
# Our environment
set osname [uname sysname]
setenv TREELITE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(TREELITE_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(TREELITE_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(TREELITE_ROOT)/lib")
EoF
