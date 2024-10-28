package: lzma
version: "%(tag_basename)s"
tag: "v5.2.3"
source: https://github.com/alisw/liblzma
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <lzma.h>\n" | c++ -xc++ - -c -M 2>&1
---
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./autogen.sh
./configure CFLAGS="$CFLAGS -fPIC -Ofast" \
            --prefix="$INSTALLROOT"       \
            --disable-shared              \
            --enable-static               \
            --disable-nls                 \
            --disable-rpath               \
            --disable-dependency-tracking \
            --disable-doc
make ${JOBS+-j $JOBS} install
rm -f "$INSTALLROOT"/lib/*.la

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
set LZMA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LZMA_ROOT \$LZMA_ROOT
set BASEDIR \$::env(BASEDIR)
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin
EoF
