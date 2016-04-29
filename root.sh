package: ROOT
version: "%(tag_basename)s-alice%(defaults_upper)s"
tag: alice/v5-34-30
source: https://github.com/alisw/root
requires: 
  - AliEn-Runtime:(?!.*ppc64)
  - GSL
env:
  ROOTSYS: "$ROOT_ROOT"
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  cd $INSTALLROOT/test
  env PATH=$INSTALLROOT/bin:$PATH LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH make ${JOBS+-j$JOBS}
---
#!/bin/bash -e
unset ROOTSYS

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++
[[ "$CXXFLAGS" != *'-std=c++11'* ]] || CXX11=1

case $ARCHITECTURE in
  osx*)
    ENABLE_COCOA=1
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $OPENSSL_ROOT ]] && SYS_OPENSSL_ROOT=`brew --prefix openssl`
  ;;
esac

cmake $SOURCEDIR                                                \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN_DIR=$ALIEN_RUNTIME_ROOT}    \
      ${ALIEN_RUNTIME_ROOT:+-DMONALISA_DIR=$ALIEN_RUNTIME_ROOT} \
      ${XROOTD_ROOT:+-DXROOTD_ROOT_DIR=$ALIEN_RUNTIME_ROOT}     \
      -Dhttp=ON                                                 \
      ${CXX11:+-Dcxx11=ON}                                      \
      -Dbuiltin_freetype=ON                                     \
      -Dbuiltin_pcre=ON                                         \
      ${ENABLE_COCOA:+-Dcocoa=ON}                               \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                        \
      -DCMAKE_C_COMPILER=$COMPILER_CC                           \
      -DCMAKE_LINKER=$COMPILER_LD                               \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$ALIEN_RUNTIME_ROOT}       \
      ${SYS_OPENSSL_ROOT:+-DOPENSSL_ROOT=$SYS_OPENSSL_ROOT}     \
      ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$ALIEN_RUNTIME_ROOT}       \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                          \
      -Dminuit2=ON                                              \
      -Dpythia6_nolink=ON                                       \
      -Droofit=ON                                               \
      -Dsoversion=ON                                            \
      -Dvdt=ON

# Check if essential features are enabled
bin/root-config --features
for FEATURE in http builtin_freetype builtin_pcre mathmore xml \
               ssl opengl minuit2 pythia6 roofit soversion vdt \
               ${CXX11:+cxx11} ${XROOTD_ROOT:+xrootd}          \
               ${ALIEN_RUNTIME_ROOT:+alien monalisa}
do
  bin/root-config --has-$FEATURE | grep -q yes
done

make ${JOBS+-j$JOBS} install
pushd $INSTALLROOT/test
  # Compile ROOT tests
  env PATH=$INSTALLROOT/bin:$PATH LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH make ${JOBS+-j$JOBS}
popd

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${ALIEN_RUNTIME_ROOT:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION} ${GSL_VERSION:+GSL/$GSL_VERSION-$GSL_REVISION}
# Our environment
setenv ROOT_RELEASE \$version
setenv ROOT_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv ROOTSYS \$::env(ROOT_BASEDIR)/\$::env(ROOT_RELEASE)
prepend-path PATH \$::env(ROOTSYS)/bin
prepend-path LD_LIBRARY_PATH \$::env(ROOTSYS)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ROOTSYS)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
