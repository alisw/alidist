package: GCC-Toolchain
version: "%(tag_basename)s"
tag: v7.3.0-alice2
source: https://github.com/alisw/gcc-toolchain
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
build_requires:
  - "autotools:(slc6|slc7)"
  - yacc-like
  - make
prefer_system: .*
prefer_system_check: |
  set -e
  which gfortran || { echo "gfortran missing"; exit 1; }
  case $REQUESTED_VERSION in
    v12*) MIN_GCC_VERSION=120100 ;;
    v10*) MIN_GCC_VERSION=100200 ;;
    *) MIN_GCC_VERSION=70300 ;;
  esac
  which gcc
  test -f "$(dirname "$(which gcc)")/c++"
  gcc -xc++ - -c -o /dev/null << EOF
  #define GCCVER ((__GNUC__ * 10000)+(__GNUC_MINOR__ * 100)+(__GNUC_PATCHLEVEL__))
  #if (GCCVER < $MIN_GCC_VERSION)
  #error "System's GCC cannot be used: we need at least ($MIN_GCC_VERSION/1e4), while we intend to go for GCC $REQUESTED_VERSION. We'll compile our own version."
  #endif
  EOF
---
#!/bin/bash -e

unset CXXFLAGS
unset CFLAGS

echo "Building GCC because no compatible version was found on the system. To skip this step, install GCC 4.8 or 4.9, or 5.X (with the exception of 5.0 to 5.2). Make sure you have gfortran installed too."

USE_GOLD=
case $ARCHITECTURE in
  osx*)
    EXTRA_LANGS=',objc,obj-c++'
    MARCH=
  ;;
  *x86-64)
    MARCH='x86_64-unknown-linux-gnu'
  ;;
  *)
    MARCH=
  ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./

if [ -e autoconf-archive ]; then
  (cd autoconf-archive && autoreconf -ivf )
  mkdir build-autoconf-archive
  pushd build-autoconf-archive
    ../autoconf-archive/configure --prefix="$INSTALLROOT"
    make install
  popd
  export ACLOCAL_PATH=$INSTALLROOT/share/aclocal
fi

# Binutils
mkdir build-binutils
pushd build-binutils
  ../binutils/configure --prefix="$INSTALLROOT"                \
                        ${MARCH:+--build=$MARCH --host=$MARCH} \
                        ${USE_GOLD:+--enable-gold=yes}         \
                        --enable-ld=default                    \
                        --enable-lto                           \
                        --enable-plugins                       \
                        --enable-threads                       \
                        --disable-nls
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
popd

# Test program
cat > test.c <<EOF
#include <string.h>
#include <stdio.h>
int main(void) { printf("The answer is 42.\n"); }
EOF

pushd gcc
[ -e mpfr ] && (cd mpfr && autoreconf -ivf)
[ -e mpc ] && (cd mpc && autoreconf -ivf)
[ -e gmp ] && (cd gmp && autoreconf -ivf)
[ -e isl ] && (cd isl && autoreconf -ivf)
[ -e cloog ] && (cd cloog && autoreconf -ivf)
popd
[ -e mpfr ] && (cd mpfr && autoreconf -ivf)
[ -e mpc ] && (cd mpc && autoreconf -ivf)
[ -e gmp ] && (cd gmp && autoreconf -ivf)
[ -e isl ] && (cd isl && autoreconf -ivf)
[ -e cloog ] && (cd cloog && autoreconf -ivf)

mkdir build-gcc
pushd build-gcc
  ../gcc/configure --prefix="$INSTALLROOT"                          \
                   ${MARCH:+--build=$MARCH --host=$MARCH}           \
                   --enable-languages="c,c++,fortran${EXTRA_LANGS}" \
                   --disable-multilib                               \
                   ${USE_GOLD:+--enable-gold=yes}                   \
                   --enable-ld=default                              \
                   --enable-lto                                     \
                   --disable-nls
  make ${JOBS+-j $JOBS} bootstrap-lean MAKEINFO=":"
  make install MAKEINFO=":"
  (if cd gmp || cd ../gmp; then make install MAKEINFO=":"; fi)
  hash -r

  # GCC creates c++, but not cc
  ln -nfs gcc "$INSTALLROOT/bin/cc"
  rm -rf "$INSTALLROOT/lib/pkg-config"

  # Provide a custom specs file if needed
  #SPEC="$(dirname $(gcc -print-libgcc-file-name))/specs"
  #gcc -dumpspecs > $SPEC
  #perl -pe '++$x and next if /^\*link:/; $x-- and s/^(.*)$/\1 -rpath-link \/lib64:\/lib/ if $x' $SPEC > $SPEC.0
  #mv $SPEC.0 $SPEC

  rm -f "$INSTALLROOT"/lib/*.la \
        "$INSTALLROOT"/lib64/*.la
popd

# From now on, use own linker and GCC
export PATH="$INSTALLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALLROOT/lib64:$INSTALLROOT/lib:$LD_LIBRARY_PATH"
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
  ../gdb/configure --prefix="$INSTALLROOT"                \
                   ${MARCH:+--build=$MARCH --host=$MARCH} \
                   --without-python                       \
                   --disable-multilib
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
  rm -f "$INSTALLROOT"/lib/*.la
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
# Load Toolchain module for the current platform. Fallback on this one
regexp -- "^(.*)/.*\$" [module-info name] dummy mod_name
if { "\$mod_name" == "GCC-Toolchain" } {
  if { [regexp {^/cvmfs.*} \$ModulesCurrentModulefile dummy1 dummy2] } {
    module load Toolchain/GCC-${PKGVERSION//-*}
    if { [is-loaded Toolchain] } { continue }
  }
  set base_path \$::env(BASEDIR)
} else {
  # Loading Toolchain: autodetect prefix
  set base_path [string map "/etc/toolchain/modulefiles/ /" \$ModulesCurrentModulefile]
  set base_path [string map "/Modules/modulefiles/ /" \$base_path]
  regexp -- "^(.*)/.*/.*\$" \$base_path dummy base_path
  set base_path \$base_path/Packages
  # Load any fundamental packages we need in the runtime environment, if
  # loading off CVMFS (because there we have a grid-base-packages/default
  # symlink). Don't depend on that package directly here, so that we don't
  # rebuild our entire stack when changing what we use in grid-base-packages.
  if { [regexp {^/cvmfs.*} \$ModulesCurrentModulefile dummy1 dummy2] } {
    module load grid-base-packages/default
  }
}
# Our environment
set GCC_TOOLCHAIN_ROOT \$base_path/GCC-Toolchain/\$version
prepend-path LD_LIBRARY_PATH \$GCC_TOOLCHAIN_ROOT/lib
prepend-path LD_LIBRARY_PATH \$GCC_TOOLCHAIN_ROOT/lib64
prepend-path PATH \$GCC_TOOLCHAIN_ROOT/bin
EoF
