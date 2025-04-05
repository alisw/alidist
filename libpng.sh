package: libpng
version: v1.6.47
requires:
  - zlib
build_requires:
  - CMake
source: https://github.com/pnggroup/libpng
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <png.h>\n" | c++ -xc++ - `libpng-config --cflags` -c -M 2>&1
  if [ $? -ne 0 ]; then printf "libpng was not found.\n * On RHEL-compatible systems you probably need: libpng libpng-devel\n * On Ubuntu-compatible systems you probably need: libpng12-0 libpng12-dev"; exit 1; fi
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
cmake .                                        \
    -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLROOT   \
    -DCMAKE_CXX_STANDARD=${CXXSTD}             \
    -DBUILD_SHARED_LIBS=YES                    \
    ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}  \
    -DCMAKE_SKIP_RPATH=YES                     \
    -DSKIP_INSTALL_FILES=1                     \
    -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j $JOBS}
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
module load BASE/1.0 $([[ $ALIEN_RUNTIME_VERSION ]] && echo "AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION" || echo "${ZLIB_REVISION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}")
# Our environment
set LIBPNG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$LIBPNG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LIBPNG_ROOT/lib
EoF
