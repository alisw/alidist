package: libtirpc
version: "%(tag_basename)s"
tag: "libtirpc-1-1-4"
source: https://github.com/alisw/libtirpc
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./bootstrap
./configure --enable-shared=no --disable-gssapi --prefix=${INSTALLROOT}
make ${JOBS+-j $JOBS} install
rm -rf ${INSTALLROOT}/share "${INSTALLROOT}"/lib/*.la "${INSTALLROOT}"/lib/pkgconfig

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set LIBTIRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LIBTIRPC_ROOT \$LIBTIRPC_ROOT
prepend-path LD_LIBRARY_PATH \$LIBTIRPC_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
