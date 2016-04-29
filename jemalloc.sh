package: jemalloc
version: "v%(commit_hash)s%(defaults_upper)s"
source: https://github.com/jemalloc/jemalloc
tag: 4.1.0
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - autotools
---
#!/bin/bash
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
setenv JEMALLOC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JEMALLOC_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JEMALLOC_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(JEMALLOC_ROOT)/lib")
setenv LD_PRELOAD \$::env(JEMALLOC_ROOT)/lib/libjemalloc.so
EoF
