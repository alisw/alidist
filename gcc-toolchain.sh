package: GCC-Toolchain
version: "%(tag_basename)s"
tag: v14.2.0-alice2
source: https://github.com/alisw/gcc-toolchain
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
  "PATH": "$GCC_TOOLCHAIN_ROOT/libexec/bin"
build_requires:
  - "autotools:(slc6|slc7)"
  - yacc-like
  - make
prefer_system: .*
prefer_system_check: |
  set -e
  which gfortran || { echo "gfortran missing"; exit 1; }
  case $REQUESTED_VERSION in
    v14*) MIN_GCC_VERSION=140200 ;;
    v13*) MIN_GCC_VERSION=130200 ;;
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
env:
  CCACHE_CONFIGPATH: "$GCC_TOOLCHAIN_ROOT/etc/ccache.conf"
---
# Fix syntax highlight
cat <<EOF
EOF
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
                        --enable-gprofng=no                    \
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

# We will need to rebuild them with the final GCC
rsync -a gcc/mpfr/ mpfr
rsync -a gcc/gmp/ gmp
rsync -a gcc/isl/ isl
rsync -a gcc/mpc/ mpc

pushd gcc
  [ -d mpfr ] && (cd mpfr && autoreconf -ivf)
  [ -d mpc ] && (cd mpc && autoreconf -ivf)
  [ -d gmp ] && (cd gmp && autoreconf -ivf)
  [ -d isl ] && (cd isl && autoreconf -ivf)
  [ -d cloog ] && (cd cloog && autoreconf -ivf)
popd

[ -d mpfr ] && (cd mpfr && autoreconf -ivf)
[ -d mpc ] && (cd mpc && autoreconf -ivf)
[ -d gmp ] && (cd gmp && autoreconf -ivf)
[ -d isl ] && (cd isl && autoreconf -ivf)
[ -d cloog ] && (cd cloog && autoreconf -ivf)

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
type ld
type g++
g++ test.c
./a.out
rm -f a.out

# Build a very basic CMake, to compile ccache and nothing else
# in case we manage, we build ccache
if [ -e ccache ]; then
  mkdir -p build-cmake
  pushd build-cmake
  cat > build-flags.cmake <<- EOF
# Disable Java capabilities; we don't need it and on OS X might miss the
# required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
SET(JNI_H FALSE CACHE BOOL "" FORCE)
SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

# SL6 with GCC 4.6.1 and LTO requires -ltinfo with -lcurses for link to succeed,
# but cmake is not smart enough to find it. We do not really need ccmake anyway,
# so just disable it.
SET(BUILD_CursesDialog FALSE CACHE BOOL "" FORCE)
EOF
    $SOURCEDIR/cmake/bootstrap --prefix=$BUILDDIR/bootstrap-cmake \
                               --no-debugger                      \
                               --no-qt-gui                        \
                               --init=build-flags.cmake           \
                               ${JOBS:+--parallel=$JOBS}
    make ${JOBS+-j $JOBS}
    make install/strip
  popd

  # We build ccache using our own compiler, so that we do not have issue
  # with libstdc++ compatibility.
  mkdir build-ccache
  pushd build-ccache
    $BUILDDIR/bootstrap-cmake/bin/cmake -S ../ccache \
        -DENABLE_DOCUMENTATION=OFF                   \
        -DENABLE_TESTING=OFF                         \
        -DSTATIC_LINK=ON                             \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT/libexec/ccache"
    make ${JOBS:+-j $JOBS} install
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/gcc
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/g++
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/cc
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/c++
    export PATH=$INSTALLROOT/libexec/ccache/bin:$PATH
    # Notice how we configure CCACHE to work, but then 
    # disable so that users need to export CCACHE_DISABLE=false
    # to actually have it working.
    mkdir -p $INSTALLROOT/libexec/ccache/etc
    cat > $INSTALLROOT/libexec/ccache/etc/ccache.conf <<EOF
cache_dir=$WORK_DIR/TMP/ccache/$ARCHITECTURE
disable=true
EOF
  popd
fi

# We rebuild mpfr, gmp, isl to be used with gdb. We do so because
# we want to make sure they were actually built with the GCC we
# use, not with the bootstrap xgcc.
[ -d mpfr ] && (cd mpfr && autoreconf -ivf)
[ -d gmp ] && (cd gmp && autoreconf -ivf)
[ -d isl ] && (cd isl && autoreconf -ivf)
[ -d mpc ] && (cd mpc && autoreconf -ivf)
mkdir -p build-gmp
mkdir -p build-mpfr
mkdir -p build-isl
mkdir -p build-mpc

pushd build-gmp
  ../gmp/configure --prefix="$INSTALLROOT/libexec/extra"  \
                   --disable-shared                       \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-mpfr
  ../mpfr/configure --prefix="$INSTALLROOT/libexec/extra"  \
                   --disable-shared                        \
                   --with-gmp="$INSTALLROOT/libexec/extra" \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-isl
  ../isl/configure --prefix="$INSTALLROOT/libexec/extra"          \
                   --with-gmp-prefix="$INSTALLROOT/libexec/extra" \
                   --disable-shared                               \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-mpc
  ../mpc/configure --prefix="$INSTALLROOT/libexec/extra"    \
                   --disable-shared                         \
                   --with-gmp="$INSTALLROOT/libexec/extra"  \
                   --with-mpft="$INSTALLROOT/libexec/extra" \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

# GDB
mkdir build-gdb
pushd build-gdb
  ../gdb/configure --prefix="$INSTALLROOT"                \
                   ${MARCH:+--build=$MARCH --host=$MARCH} \
                   --with-gmp=$INSTALLROOT/libexec/extra  \
                   --with-mpfr=$INSTALLROOT/libexec/extra \
                   --with-isl=$INSTALLROOT/libexec/extra  \
                   --with-mpc=$INSTALLROOT/libexec/extra  \
                   --without-guile                        \
                   --without-python                       \
                   --disable-multilib
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
  rm -f "$INSTALLROOT"/lib/*.la
popd

# We remove the sim folder because it's not used and actually
# conflicts with FairRoot when installing in a single installation
# path.
rm -fr "$INSTALLROOT"/include/sim
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
prepend-path PATH \$GCC_TOOLCHAIN_ROOT/libexec/ccache/bin
EoF
