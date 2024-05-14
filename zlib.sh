package: zlib
version: "%(tag_basename)s"
tag: v1.2.8
source: https://github.com/star-externals/zlib
build_requires:
  - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <zlib.h>\n" | cc -xc++ - -c -M 2>&1
---
#!/bin/sh

echo "Building ALICE zlib. To avoid this install zlib development package."
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

case $ARCHITECTURE in
   *_amd64_gcc4[56789]*)
     CFLAGS="-fPIC -O3 -DUSE_MMAP -DUNALIGNED_OK -D_LARGEFILE64_SOURCE=1 -msse3" \
     ./configure --prefix=$INSTALLROOT
     ;;
   *_armv7hl_gcc4[56789]* )
     CFLAGS="-fPIC -O3 -DUSE_MMAP -DUNALIGNED_OK -D_LARGEFILE64_SOURCE=1" \
     ./configure --prefix=$INSTALLROOT
     ;;
   * )
     ./configure --prefix=$INSTALLROOT
   ;;
esac
make ${JOBS+-j $JOBS}
make install
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
set BASEDIR \$::env(BASEDIR)
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
