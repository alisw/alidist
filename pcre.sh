package: PCRE
version: master
tag: master
source: https://github.com/ktf/pcre
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include \"pcre.h\"\n" | cc -I$(brew --prefix pcre)/include -xc - -c -o /dev/null
---
#!/bin/sh
echo "Building our own pcre. If you want to avoid this, please install pcre development package."

$SOURCEDIR/configure --enable-unicode-properties \
                     --enable-pcregrep-libz \
                     --enable-pcregrep-libbz2 \
                     --prefix=$INSTALLROOT

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set BASEDIR \$::env(BASEDIR)
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
