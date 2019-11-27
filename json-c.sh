package: json-c
version: "v0.13.1"
tag: "json-c-0.13.1-20180305"
source: https://github.com/json-c/json-c
build_requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
autoreconf -ivf
./configure --disable-shared --enable-static --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv JSON_C_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$JSON_C_ROOT/bin
prepend-path LD_LIBRARY_PATH \$JSON_C_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
