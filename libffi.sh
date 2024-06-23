package: libffi
version: v3.2.1
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/libffi/libffi
prepend_path:
  LD_LIBRARY_PATH: "$LIBFFI_ROOT/lib64"
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
autoreconf -ivf .
MAKEINFO=: ./configure --prefix=$INSTALLROOT --disable-docs
make ${JOBS:+-j $JOBS} MAKEINFO=:
make install MAKEINFO=:

LIBPATH=$(find $INSTALLROOT -name libffi.so -o -name libffi.dylib -o -name libffi.a | head -n 1)
# Do not install info documentation
rm -fr "$INSTALLROOT/share/info"

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
module load BASE/1.0
# Our environment
set LIBFFI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$LIBFFI_ROOT/$(basename $(dirname $LIBPATH))
EoF
