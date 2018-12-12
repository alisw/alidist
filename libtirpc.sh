package: libtirpc
version: "%(tag_basename)s"
tag: "libtirpc-1-1-4"
source: git://git.linux-nfs.org/projects/steved/libtirpc.git
build_requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./bootstrap
./configure --enable-shared=no --prefix=${INSTALLROOT}
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
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv LIBTIRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(LIBTIRPC_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(LIBTIRPC_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
