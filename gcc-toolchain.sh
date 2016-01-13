package: GCC-Toolchain
version: "%(tag_basename)s%(defaults_upper)s"
source: https://github.com/alisw/gcc-toolchain
tag: alice/v4.9.3
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
  "DYLD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
build_requires:
 - autotools
prefer_system: .*
prefer_system_check: |
  printf "#if ((__GNUC__ << 16)+(__GNUC_MINOR__ << 8)+(__GNUC_PATCHLEVEL__) < (0x040800))\n#error \"Cannot use system's GCC.\"\n#endif\n" | gcc -xc++ - -c -o /dev/null
---
#!/bin/bash -e

echo "Building ALICE GCC. You can skip this step by installing at least GCC 4.8 on your system."

USE_GOLD=
case $ARCHITECTURE in
  osx*)
    EXTRA_LANGS=',objc,obj-c++'
  ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./

# Binutils
mkdir build-binutils
pushd build-binutils
  ../binutils/configure --prefix="$INSTALLROOT" \
                        ${USE_GOLD:+--enable-gold=yes} \
                        --enable-ld=default \
                        --enable-lto \
                        --enable-plugins \
                        --enable-threads \
                        --disable-nls
  make ${JOBS:+-j$JOBS}
  make install
  hash -r
popd

# Test program
cat > test.c <<EOF
#include <string.h>
#include <stdio.h>
int main(void) { printf("The answer is 42.\n"); }
EOF

# GCC and deps
pushd gcc
  for EXT in mpfr gmp mpc isl cloog; do
    pushd $EXT
      autoreconf -ivf
    popd
  done
popd

mkdir build-gcc
pushd build-gcc
  ../gcc/configure --prefix="$INSTALLROOT" \
               --enable-languages="c,c++,fortran${EXTRA_LANGS}" \
               --disable-multilib \
               ${USE_GOLD:+--enable-gold=yes} \
               --enable-ld=default \
               --enable-lto \
               --disable-nls
  make ${JOBS+-j $JOBS} bootstrap-lean
  make install
  hash -r

  # GCC creates c++, but not cc
  ln -nfs gcc "$INSTALLROOT/bin/cc"
  rm -rf "$INSTALLROOT/lib/pkg-config"

  # Provide a custom specs file if needed
  #SPEC="$(dirname $(gcc -print-libgcc-file-name))/specs"
  #gcc -dumpspecs > $SPEC
  #perl -pe '++$x and next if /^\*link:/; $x-- and s/^(.*)$/\1 -rpath-link \/lib64:\/lib/ if $x' $SPEC > $SPEC.0
  #mv $SPEC.0 $SPEC

  rm -f $INSTALLROOT/lib/*.la \
        $INSTALLROOT/lib64/*.la
popd

# From now on, use own linker and GCC
export PATH="$INSTALLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALLROOT/lib64:$INSTALLROOT/lib:$LD_LIBRARY_PATH"
export DYLD_LIBRARY_PATH="$INSTALLROOT/lib64:$INSTALLROOT/lib:$DYLD_LIBRARY_PATH"
hash -r

# Test own linker and own GCC
which ld
which g++
g++ test.c
./a.out
rm -f a.out

# GDB
mkdir build-gdb
pushd build-gdb
  ../gdb/configure --prefix="$INSTALLROOT" \
                   --disable-multilib
  make ${JOBS:+-j$JOBS}
  make install
  hash -r
  rm -f $INSTALLROOT/lib/*.la
popd

# If fixincludes is not desired, see:
# http://ewontfix.com/12/
# https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/eclass/toolchain.eclass?view=markup&sortby=log#l1524

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
setenv GCC_TOOLCHAIN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GCC_TOOLCHAIN_ROOT)/lib
prepend-path LD_LIBRARY_PATH \$::env(GCC_TOOLCHAIN_ROOT)/lib64
prepend-path PATH \$::env(GCC_TOOLCHAIN_ROOT)/bin
EoF
