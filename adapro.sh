package: ADAPRO
version: "%(tag_basename)s"
tag: master
source: https://gitlab.cern.ch/adapos/adapro.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
prepend_path:
  ROOT_INCLUDE_PATH: "$ADAPRO_ROOT/include/adapro"

---
#!/bin/sh

# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
cd $BUILDDIR
make CONF=No_DIM ${JOBS+-j $JOBS}
make install PREFIX="$INSTALLROOT"

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
set ADAPRO_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ADAPRO_ROOT \$ADAPRO_ROOT
prepend-path LD_LIBRARY_PATH \$ADAPRO_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$ADAPRO_ROOT/include/adapro
EoF
