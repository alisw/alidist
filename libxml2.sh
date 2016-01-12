package: libxml2
version: v2.9.2
source: git://git.gnome.org/libxml2
tag: v2.9.2
build_requires:
  - autotools
  - zlib
  - "GCC-Toolchain:(?!osx|slc5)"
prefer_system: "(?!slc5)"
prefer_system_check: which xml2-config
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
