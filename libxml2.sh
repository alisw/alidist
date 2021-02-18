package: libxml2
version: "%(tag_basename)s"
tag: v2.9.3
build_requires:
  - "autotools:(slc6|slc7)"
  - zlib
  - "GCC-Toolchain:(?!osx)"
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
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${ZLIB_REVISION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}
# Our environment
setenv LIBXML2_VERSION \$version
set LIBXML2_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(LIBXML2_VERSION)
setenv LIBXML2_ROOT \$LIBXML2_ROOT
prepend-path PATH \$LIBXML2_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LIBXML2_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
