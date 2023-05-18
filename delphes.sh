package: Delphes
version: "%(tag_basename)s"
tag: v20210729
requires:
  - ROOT
  - HepMC
  - pythia
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/delphes.git
# prepend_path:
#   LD_LIBRARY_PATH: "$DELPHES_ROOT/lib"
#   ROOT_INCLUDE_PATH: "$DELPHES_ROOT/include"
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
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PYTHIA_REVISION:+pythia/$PYTHIA_VERSION-$PYTHIA_REVISION}                             \\
            ${HEPMC_REVISION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION}                                 \\
            ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}                                     \\

# Delphes environment:
set DELPHES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv DELPHES_ROOT \$DELPHES_ROOT

prepend-path PATH \$DELPHES_ROOT/bin
prepend-path LD_LIBRARY_PATH \$DELPHES_ROOT/lib
prepend-path LD_LIBRARY_PATH \$DELPHES_ROOT/lib64
prepend-path ROOT_INCLUDE_PATH \$DELPHES_ROOT/include

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
