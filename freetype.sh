package: FreeType
version: v2.10.1
requires:
 - AliEn-Runtime:(?!.*ppc64)
build_requires:
  - "autotools:(slc6|slc7)"
  - system-curl
  - alibuild-recipe-tools
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <ft2build.h>\n" | c++ -xc++ - `freetype-config --cflags` -c -M 2>&1;
  if [ $? -ne 0 ]; then printf "FreeType is missing on your system.\n * On RHEL-compatible systems you probably need: freetype freetype-devel\n * On Ubuntu-compatible systems you probably need: libfreetype6 libfreetype6-dev\n"; exit 1; fi
---
#!/bin/bash -ex
URL="http://download.savannah.gnu.org/releases/freetype/freetype-${PKGVERSION:1}.tar.gz"
curl -L -o freetype.tgz $URL
tar xzf freetype.tgz
rm -f freetype.tgz
cd freetype-${PKGVERSION:1}
./configure --prefix=$INSTALLROOT                \
            --with-png=no                        \
            ${ZLIB_ROOT:+--with-zlib=$ZLIB_ROOT}

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env > "$MODULEDIR/$PKGNAME"
