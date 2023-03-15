package: jemalloc
version: "v%(commit_hash)s"
tag: 5.1.0
source: https://github.com/jemalloc/jemalloc
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "autotools:(slc6|slc7)"
---
#!/bin/bash -e
rsync -a --delete --exclude "**/.git" $SOURCEDIR/ .
./autogen.sh
./configure --prefix=$INSTALLROOT
make ${JOBS+-j$JOBS}
for INSTALL_TARGET in bin include lib_shared lib_static lib; do
  make install_${INSTALL_TARGET}
done

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set JEMALLOC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv JEMALLOC_ROOT \$JEMALLOC_ROOT
prepend-path PATH \$JEMALLOC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$JEMALLOC_ROOT/lib
setenv LD_PRELOAD \$::env(JEMALLOC_ROOT)/lib/libjemalloc.so
EoF
