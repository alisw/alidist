package: libuv
version: v1.38.0
source: https://github.com/libuv/libuv
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include <uv.h>" | c++ -I$(brew --prefix libuv)/include -xc++ - -c -o /dev/null 2>&1
---
#!/bin/sh
cmake $SOURCEDIR                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                    \
      -DCMAKE_INSTALL_LIBDIR=lib

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
set LIBUV_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$LIBUV_ROOT/lib
EoF
