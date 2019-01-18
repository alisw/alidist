package: hdf5
version: "%(tag_basename)s"
tag: hdf5-1_10_4
source: https://github.com/live-clones/hdf5.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - cmake
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <hdf5.h>\n" | gcc -xc++ - -c -o /dev/null
---
#!/bin/bash -e
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

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
setenv HDF5_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(HDF5_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(HDF5_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(HDF5_ROOT)/lib")
EoF