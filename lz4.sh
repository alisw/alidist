package: lz4
version: "%(tag_basename)s"
tag: v1.8.3
source: https://github.com/lz4/lz4
build_requires:
 - "GCC-Toolchain:(?!osx)"
prefer_system: ".*"
prefer_system_check: |
  printf "#include <lz4.h>\n" | gcc -xc++ -I$(brew --prefix lz4)/include - -c -M 2>&1
---

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ ./
make -j ${JOBS+-j $JOBS}
make PREFIX=$INSTALLROOT INCLUDEDIR=$INSTALLROOT/include install

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
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
