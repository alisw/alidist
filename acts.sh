package: ACTS
version: v23.4.0
build_requires:
    - "GCC-Toolchain:(?!osx)"
    - CMake
    - boost
source: https://github.com/acts-project/acts.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS}

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
# ACTS environment
set ACTS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ACTS_ROOT \$ACTS_ROOT

prepend-path PATH \$ACTS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ACTS_ROOT/lib
prepend-path LD_LIBRARY_PATH \$ACTS_ROOT/lib64
prepend-path ROOT_INCLUDE_PATH \$ACTS_ROOT/include
EoF