package: DimRpcParallel
version: "%(tag_basename)s"
tag: v0.1.3
requires:
  - "dim:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
source: https://gitlab.cern.ch/alialfred/DimRpcParallel.git
---
#!/bin/bash -e

cmake $SOURCEDIR                                                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                             \
      ${DIM_REVISION:+-DDIM_ROOT=$DIM_ROOT}

make ${JOBS+-j $JOBS} install

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
module load BASE/1.0                                                          \\
            ${DIM_REVISION:+dim/$DIM_VERSION-$DIM_REVISION}                    \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set DIM_RPC_PARALLEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv DIM_RPC_PARALLEL_ROOT \$DIM_RPC_PARALLEL_ROOT
set BASEDIR \$::env(BASEDIR)
prepend-path LD_LIBRARY_PATH \$DIM_RPC_PARALLEL_ROOT/lib

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
