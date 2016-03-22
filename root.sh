package: ROOT
version: "%(tag_basename)s-%(short_hash)s"
source: https://github.com/root-mirror/root
tag: v6-06-00-patches
requires: 
  - AliEn-Runtime:(?!.*ppc64)
  - GSL
env:
  ROOTSYS: "$ROOT_ROOT"
incremental_recipe: |
  export ROOTSYS=$BUILDDIR
  make ${JOBS:+-j$JOBS}
  export ROOTSYS=$INSTALLROOT
  make install
---
#!/bin/bash -e

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++

case $ARCHITECTURE in 
  osx*)
    ENABLE_COCOA=true
    DISABLE_FINK=true
    WITH_CLANG=true
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
  ;;
esac

export ROOTSYS=$BUILDDIR
case $ARCHITECTURE in
  *ppc64)
    cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
  ;;
  *)
"$SOURCEDIR/configure"                         \
  --with-pythia6-uscore=SINGLE                 \
  --with-alien-incdir=$GSHELL_ROOT/include     \
  --with-alien-libdir=$GSHELL_ROOT/lib         \
  --with-monalisa-incdir=$GSHELL_ROOT/include  \
  --with-monalisa-libdir=$GSHELL_ROOT/lib      \
  --with-xrootd=$GSHELL_ROOT                   \
  --enable-http                                \
  --enable-minuit2                             \
  --enable-roofit                              \
  --enable-soversion                           \
  --enable-builtin-freetype                    \
  --enable-builtin-pcre                        \
  --enable-mathmore                            \
  ${ENABLE_COCOA+--enable-cocoa}               \
  --disable-bonjour                            \
  ${DISABLE_FINK+--disable-fink}               \
  --with-f77=gfortran                          \
  --with-cc=$COMPILER_CC                       \
  --with-cxx=$COMPILER_CXX                     \
  --with-ld=$COMPILER_LD                       \
  ${CXXFLAGS:+--cxxflags="$CXXFLAGS"}          \
  ${WITH_CLANG+--with-clang}                   \
  --disable-shadowpw                           \
  --disable-astiff                             \
  ${LIBXML2_ROOT:+--with-xml-incdir=$ALIEN_RUNTIME_ROOT/include/libxml2 --with-xml-libdir=$ALIEN_RUNTIME_ROOT/lib}  \
  --disable-globus                               \
  --with-ssl-libdir=$ALIEN_RUNTIME_ROOT/lib      \
  --with-ssl-incdir=$ALIEN_RUNTIME_ROOT/include  \
  --with-ssl-shared=yes                          \
  --enable-mysql
  ;;
esac

[[ "$ALIEN_RUNTIME_ROOT" == '' ]] || ./bin/root-config --has-alien | grep -q yes
./bin/root-config --has-opengl | grep -q yes
./bin/root-config --has-xml | grep -q yes

make ${JOBS+-j$JOBS}
export ROOTSYS=$INSTALLROOT
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
module load BASE/1.0 AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION ${GSL_VERSION:+GSL/$GSL_VERSION-$GSL_REVISION}
# Our environment
setenv ROOT_RELEASE \$version
setenv ROOT_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv ROOTSYS \$::env(ROOT_BASEDIR)/\$::env(ROOT_RELEASE)
prepend-path PATH \$::env(ROOTSYS)/bin
prepend-path LD_LIBRARY_PATH \$::env(ROOTSYS)/lib
EoF
