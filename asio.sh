package: asio
version: "%(tag_basename)s"
tag: v1.19.1
source: https://github.com/FairRootGroup/asio
build_requires:
  - CMake
prepend_path:
  ROOT_INCLUDE_PATH: "$ASIO_ROOT/include"
---
#!/bin/sh

cmake -S $SOURCEDIR -B .                                        \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . --target install

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
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
set ASIO_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$ASIO_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
