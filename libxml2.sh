package: libxml2
version: "%(tag_basename)s"
tag: v2.15.3
license: MIT
build_requires:
  - "autotools:(slc6|slc7)"
  - zlib
  - "GCC-Toolchain:(?!osx)"
  - ninja
  - CMake
  - alibuild-recipe-tools
source: https://gitlab.gnome.org/GNOME/libxml2
prefer_system: "(?!slc5)"
prefer_system_check: |
  xml2-config --version;
  if [ $? -ne 0 ]; then printf "libxml2 not found.\n * On RHEL-compatible systems you probably need: libxml2 libxml2-devel\n * On Ubuntu-compatible systems you probably need: libxml2 libxml2-dev"; exit 1; fi
---
#!/bin/sh
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DLIBXML2_WITH_ZLIB=ON \
    ${ZLIB_REVISION:+-DZLIB_ROOT=$ZLIB_ROOT}
cmake --build . -- ${JOBS:+-j$JOBS} install
# Modulefile
mkdir -p etc/modulefiles
cat > "etc/modulefiles/$PKGNAME" <<EoF
$(alibuild-generate-module --bin --lib)
# Compatibility, just in case
setenv LIBXML2_ROOT \$PKG_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
