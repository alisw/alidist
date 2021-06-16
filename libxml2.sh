package: libxml2
version: "%(tag_basename)s"
tag: v2.9.3
build_requires:
  - "autotools:(slc6|slc7)"
  - zlib
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
source: https://github.com/alisw/libxml2.git
prefer_system: "(?!slc5)"
prefer_system_check: |
  xml2-config --version;
  if [ $? -ne 0 ]; then printf "libxml2 not found.\n * On RHEL-compatible systems you probably need: libxml2 libxml2-devel\n * On Ubuntu-compatible systems you probably need: libxml2 libxml2-dev"; exit 1; fi
---
#!/bin/sh
echo "Building ALICE libxml. To avoid this install libxml development package."
rsync -a $SOURCEDIR/ ./
autoreconf -i
./configure --disable-static \
            --prefix=$INSTALLROOT \
            --with-zlib="${ZLIB_ROOT}" --without-python

make ${JOBS+-j $JOBS}
make install
# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root-env --extra > "etc/modulefiles/$PKGNAME" <<\EoF
setenv LIBXML2_VERSION $version
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
