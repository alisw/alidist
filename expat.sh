package: expat
version: v2.7.1
tag: R_2_7_1
source: https://github.com/libexpat/libexpat
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
prefer_system: ".*"
prefer_system_check: |
  pkg-config expat 2>&1 && printf "#include <expat.h>" | cc -xc -I$(brew --prefix expat)/include -c -
prepend_path:
  ROOT_INCLUDE_PATH: "$EXPAT_ROOT/include"
  CMAKE_PREFIX_PATH: "$EXPAT_ROOT"
---

cmake $SOURCEDIR/expat                                   \
      -G Ninja                                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                \
      -DBUILD_SHARED_LIBS=ON                             \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}             \
      -DCMAKE_CXX_STANDARD=${CXXSTD}                     \
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . -- ${JOBS:+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
