package: xercesc
version: Xerces-C_3_2_2
tag: v3.2.2
source: https://github.com/apache/xerces-c
build_requires:
  - CMake
prefer_system: ".*"
prefer_system_check: |
  pkg-config --atleast-version=3.2.0 xerces-c 2>&1 && printf "#include \"<xercesc/util/PlatformUtils.hpp>\"\nint main(){}" | c++ -xc - -o /dev/null
prepend_path:
  ROOT_INCLUDE_PATH: "$XERCESC_ROOT/include"
  LD_LIBRARY_PATH: "$XERCESC_ROOT/lib"
---

cmake $SOURCEDIR                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                \
      -DBUILD_SHARED_LIBS=ON                             \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}             \
      -DCMAKE_CXX_STANDARD=${CXXSTD}                     \
      -Dnetwork:BOOL=OFF                                 \
      -DCMAKE_INSTALL_LIBDIR=lib

make ${JOBS:+-j $JOBS}
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
module load BASE/1.0
# Our environment
set XERCESC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$XERCESC_ROOT/lib
EoF
