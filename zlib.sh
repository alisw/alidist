package: zlib
version: "%(tag_basename)s"
tag: v1.2.8
source: https://github.com/star-externals/zlib
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEDIR/$PKGNAME"
