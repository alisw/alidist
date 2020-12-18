package: oniguruma
version: v6.9.5
tag: v6.9.5_rev1
source: https://github.com/kkos/oniguruma/
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "autotools:(slc6|slc7)"
prefer_system: (?!slc5.*)
---
#!/bin/sh

# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
cd $BUILDDIR
./autogen.sh
./configure --prefix=$INSTALLROOT          \
            --enable-static                \
            --disable-shared               \
            --disable-dependency-tracking

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
module load BASE/1.0                                                                        \\
       ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set ONIGURUMA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$ONIGURUMA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ONIGURUMA_ROOT/lib
EoF
