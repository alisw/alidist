package: libpng
version: v1.6.18
requires:
 - AliEn-Runtime:(?!.*ppc64)
build_requires:
 - CMake
source: git://git.code.sf.net/p/libpng/code
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include <png.h>\n" | gcc -xc++ - `libpng-config --cflags` -c -M 2>&1
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
cmake .                                        \
    -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLROOT   \
    -DBUILD_SHARED_LIBS=YES                    \
    ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}  \
    -DCMAKE_SKIP_RPATH=YES                     \
    -DSKIP_INSTALL_FILES=1
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
module load BASE/1.0 ${ZLIB_ROOT:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}
# Our environment
setenv LIBPNG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(LIBPNG_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LIBPNG_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(LIBPNG_ROOT)/lib")
EoF
