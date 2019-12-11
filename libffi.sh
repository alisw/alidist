package: libffi
version: v3.2.1
build_requires:
 - autotools
source: https://github.com/libffi/libffi
prepend_path:
  LD_LIBRARY_PATH: "$LIBFFI_ROOT/lib64"
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
autoreconf -ivf .
./configure --prefix=$INSTALLROOT --disable-docs
make ${JOBS:+-j $JOBS}
make install

LIBPATH=$(find $INSTALLROOT -name libffi.so)

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
set BASEDIR \$::env(BASEDIR)
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/$(basename $(dirname $LIBPATH))
EoF
