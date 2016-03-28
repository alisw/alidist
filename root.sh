package: ROOT
version: "%(tag_basename)s-alice%(defaults_upper)s"
tag: alice/v5-34-30
source: https://github.com/alisw/root
requires: 
  - AliEn-Runtime:(?!.*ppc64)
  - GSL
env:
  ROOTSYS: "$ROOT_ROOT"
incremental_recipe: make ${JOBS:+-j$JOBS} install
---
#!/bin/bash -e

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++
echo $CXXFLAGS | grep -q -- '-std=c++11' && CXX11=ON || true

case $ARCHITECTURE in 
  osx*)
    ENABLE_COCOA=1
    WITH_CLANG=1
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
  ;;
esac

cmake $SOURCEDIR                                          \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                 \
      -DALIEN_DIR=$ALIEN_RUNTIME_ROOT                     \
      -DMONALISA_DIR=$ALIEN_RUNTIME_ROOT                  \
      -DXROOTD_ROOT_DIR=$ALIEN_RUNTIME_ROOT               \
      -Dhttp=ON                                           \
      ${CXX11:+-Dcxx11=ON}                                \
      -Dbuiltin_freetype=ON                               \
      -Dbuiltin_pcre=ON                                   \
      ${ENABLE_COCOA:+-Dcocoa=ON}                         \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                  \
      -DCMAKE_C_COMPILER=$COMPILER_CC                     \
      -DCMAKE_LINKER=$COMPILER_LD                         \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$ALIEN_RUNTIME_ROOT} \
      ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$ALIEN_RUNTIME_ROOT} \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                    \
      -Dminuit2=ON                                        \
      -Dpythia6_nolink=ON                                 \
      -Droofit=ON                                         \
      -Dsoversion=ON                                      \
      -Dvdt=ON

# Check if essential features are enabled
bin/root-config --features
for FEATURE in alien monalisa xrootd http builtin_freetype          \
               builtin_pcre mathmore xml ssl opengl ${CXX11:+cxx11} \
               minuit2 pythia6 roofit soversion vdt; do
  bin/root-config --has-$FEATURE | grep -q yes
done

make ${JOBS+-j$JOBS} install

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
