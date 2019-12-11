package: treelite
version: "%(tag_basename)s"
tag: "2a12742269"
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
set BASEDIR \$::env(BASEDIR)
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin
prepend-path ROOT_INCLUDE_PATH \$BASEDIR/$PKGNAME/\$version/include
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
