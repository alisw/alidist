package: Vc
version: "%(tag_basename)s"
tag: 1.3.3-alice2
source: https://github.com/alisw/Vc.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
prepend_path:
  ROOT_INCLUDE_PATH: "$VC_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DBUILD_TESTING=OFF

make ${JOBS+-j $JOBS}
make install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set osname [uname sysname]
setenv VC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(VC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(VC_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(VC_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(VC_ROOT)/lib")
EoF
