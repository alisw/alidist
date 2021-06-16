package: Delphes
version: "%(tag_basename)s"
tag: v20210602
requires:
  - ROOT
  - HepMC
  - pythia
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
source: https://github.com/alisw/delphes.git
#prepend_path:
#  LD_LIBRARY_PATH: "$O2_ROOT/lib"
#  ROOT_INCLUDE_PATH: "$O2_ROOT/include"
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root-env --extra > "etc/modulefiles/$PKGNAME" <<\EoF
prepend-path LD_LIBRARY_PATH $PKG_ROOT/lib64
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
