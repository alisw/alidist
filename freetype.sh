package: FreeType
version: v2.10.1
tag: VER-2-10-1
source: https://github.com/freetype/freetype
requires:
  - zlib
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
prefer_system: (?!slc5)
prefer_system_check: |
  #!/bin/bash -e
  # shellcheck disable=SC2046
  c++ -xc++ - $(freetype-config --cflags 2>/dev/null) $(pkg-config freetype2 --cflags 2>/dev/null) \
      -c -M <<< "#include <ft2build.h>" 2>&1 || { cat << EOF; exit 1; }
  FreeType is missing on your system.
  * On RHEL-compatible systems you probably need: freetype freetype-devel
  * On Ubuntu-compatible systems you probably need: libfreetype6 libfreetype6-dev
  EOF
---
#!/bin/bash -e

rsync -a --exclude='**/.git' --delete --delete-excluded "${SOURCEDIR}/" ./
sh autogen.sh
./configure --prefix="${INSTALLROOT}"            \
            --with-png=no                        \
            --with-bzip2=no                      \
            --with-harfbuzz=no                   \
            ${ZLIB_ROOT:+--with-zlib="$ZLIB_ROOT"}

make ${JOBS:+-j$JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
setenv FREETYPE_ROOT \$PKG_ROOT
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"

