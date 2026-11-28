package: libjpeg
version: "3.2.1"
tag: 3.2.1
source: https://github.com/libjpeg-turbo/libjpeg-turbo
license: BSD-3-Clause
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  JPEG_INC=
  case $ARCHITECTURE in
    osx*) JPEG_INC="-I$(brew --prefix jpeg-turbo)/include" ;;
  esac
  printf '#include <stdio.h>\n#include <jpeglib.h>\nint main(){}\n' | cc $JPEG_INC -xc - -c -o /dev/null
---
cmake "$SOURCEDIR"                       \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"  \
  -DCMAKE_BUILD_TYPE=Release             \
  -DCMAKE_INSTALL_LIBDIR=lib             \
  -DENABLE_SHARED=ON                     \
  -DENABLE_STATIC=OFF

cmake --build . ${JOBS:+-- -j $JOBS}
cmake --install .

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
