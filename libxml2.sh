package: libxml2
version: "%(tag_basename)s"
tag: v2.9.3
requires:
  - zlib
  - lzma
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/libxml2.git
prefer_system: "(?!slc5)"
prefer_system_check: |
  xml2-config --version || { printf "libxml2 not found.
  * On RHEL-compatible systems you probably need: libxml2 libxml2-devel
  * On Ubuntu-compatible systems you probably need: libxml2 libxml2-dev"; exit 1; }
---
#!/bin/bash -e

echo "Building ALICE libxml. To avoid this install libxml development package."
rsync -a "${SOURCEDIR}/" ./
autoreconf -i
./configure --disable-static \
            --prefix="${INSTALLROOT}" \
            --with-zlib="${ZLIB_ROOT}" --with-lzma="${LZMA_ROOT}" --without-python

make ${JOBS+-j $JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
setenv LIBXML2_VERSION \$version
setenv LIBXML2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
