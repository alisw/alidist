package: FreeType
version: v2.10.1
tag: VER-2-10-1
source: https://github.com/freetype/freetype
requires:
  - zlib
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <ft2build.h>\n" | c++ -xc++ - `freetype-config --cflags 2>/dev/null` `pkg-config freetype2 --cflags 2>/dev/null` -c -M 2>&1;
  if [ $? -ne 0 ]; then printf "FreeType is missing on your system.\n * On RHEL-compatible systems you probably need: freetype freetype-devel\n * On Ubuntu-compatible systems you probably need: libfreetype6 libfreetype6-dev\n"; exit 1; fi
---
#!/bin/bash -ex
rsync -a --chmod=ug=rwX --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./
type libtoolize && export LIBTOOLIZE=libtoolize
type glibtoolize && export LIBTOOLIZE=glibtoolize
sh autogen.sh
./configure --prefix="$INSTALLROOT"              \
            --with-png=no                        \
            ${ZLIB_ROOT:+--with-zlib="$ZLIB_ROOT"}

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
