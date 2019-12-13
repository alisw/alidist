package: hdf5
version: "%(tag_basename)s"
tag: hdf5-1_10_4
source: https://github.com/live-clones/hdf5.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <hdf5.h>\n" | c++ -xc++ - -c -o /dev/null
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
set HDF5_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HDF5_ROOT \$HDF5_ROOT
prepend-path PATH \$HDF5_ROOT/bin
prepend-path LD_LIBRARY_PATH \$HDF5_ROOT/lib
EoF
