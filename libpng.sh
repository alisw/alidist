package: libpng
version: v1.6.47
requires:
  - zlib
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/pnggroup/libpng
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <png.h>\n" | c++ -xc++ - `libpng-config --cflags` -c -M 2>&1
  if [ $? -ne 0 ]; then printf "libpng was not found.\n * On RHEL-compatible systems you probably need: libpng libpng-devel\n * On Ubuntu-compatible systems you probably need: libpng12-0 libpng12-dev"; exit 1; fi
---
#!/bin/bash -ex
cmake ${SOURCEDIR}                             \
    -G Ninja                                   \
    -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLROOT   \
    -DCMAKE_CXX_STANDARD=${CXXSTD}             \
    -DBUILD_SHARED_LIBS=YES                    \
    ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}  \
    -DCMAKE_SKIP_RPATH=YES                     \
    -DSKIP_INSTALL_FILES=1                     \
    -DCMAKE_INSTALL_LIBDIR=lib
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
