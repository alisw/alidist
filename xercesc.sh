package: xercesc
version: Xerces-C_3_2_4
tag: v3.2.4
source: https://github.com/apache/xerces-c
build_requires:
  - CMake
  - alibuild-recipe-tools
prefer_system: ".*"
prefer_system_check: |
  pkg-config --atleast-version=3.2.0 xerces-c 2>&1 && printf "#include \"<xercesc/util/PlatformUtils.hpp>\"\nint main(){}" | c++ -xc - -o /dev/null
prepend_path:
  ROOT_INCLUDE_PATH: "$XERCESC_ROOT/include"
  CMAKE_PREFIX_PATH: "$XERCESC_ROOT"
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
alibuild-generate-module --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set XERCESC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EOF
