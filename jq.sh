package: jq
version: v1.6
tag: jq-1.6
source: https://github.com/stedolan/jq.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - oniguruma
  - "autotools:(slc6|slc7)"
prefer_system: (?!slc5.*)
prefer_system_check: |
  type jqfoo
---
# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
cd $BUILDDIR
autoreconf -iv
./configure --prefix=$INSTALLROOT          \
            --enable-static                \
            --disable-shared               \
            --disable-maintainer-mode      \
            --with-oniguruma=$ONIGURUMA_ROOT \
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
set JQ_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$JQ_ROOT/bin
EoF
