package: FreeType
version: v2.13.3
tag: VER-2-13-3
source: https://github.com/freetype/freetype
requires:
  - zlib
license: FTL
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <ft2build.h>\n" | c++ -xc++ - `freetype-config --cflags 2>/dev/null` `pkg-config freetype2 --cflags 2>/dev/null` -c -M 2>&1;
  if [ $? -ne 0 ]; then printf "FreeType is missing on your system.\n * On RHEL-compatible systems you probably need: freetype freetype-devel\n * On Ubuntu-compatible systems you probably need: libfreetype6 libfreetype6-dev\n"; exit 1; fi
---
#!/bin/bash -ex
# Built with CMake rather than autotools: the autotools path insists on
# checking out the subprojects/dlg submodule, which is absent from our source
# copy and never compiled anyway (it is only used under FT_DEBUG_LOGGING).
cmake ${SOURCEDIR}                              \
    -G Ninja                                    \
    -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLROOT    \
    -DBUILD_SHARED_LIBS=YES                     \
    -DFT_REQUIRE_ZLIB=YES                       \
    ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}   \
    -DFT_DISABLE_HARFBUZZ=YES                   \
    -DFT_DISABLE_BROTLI=YES                     \
    -DFT_DISABLE_BZIP2=YES                      \
    -DFT_DISABLE_PNG=YES                        \
    -DCMAKE_INSTALL_LIBDIR=lib
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
