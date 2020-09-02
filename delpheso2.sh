package: DelphesO2
version: "%(tag_basename)s"
tag: master
requires:
  - ROOT
  - Delphes
  - O2
overrides:
  O2:
    version: "%(short_hash)s%(defaults_upper)s"
    tag: dev
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/preghenella/DelphesO2.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install

#ModuleFile
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
module load BASE/1.0                                                                                \\
            ${DELPHES_REVISION:+Delphes/$DELPHES_VERSION-$DELPHES_REVISION}                         \\
            ${O2_REVISION:+O2/$O2_VERSION-$O2_REVISION}

# Delphes environment:
set DELPHESO2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv DELPHESO2_ROOT \$DELPHESO2_ROOT

prepend-path PATH \$DELPHESO2_ROOT/bin
prepend-path LD_LIBRARY_PATH \$DELPHESO2_ROOT/lib
prepend-path LD_LIBRARY_PATH \$DELPHESO2_ROOT/lib64
prepend-path ROOT_INCLUDE_PATH \$DELPHESO2_ROOT/include

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
