package: ROOT
version: "%(tag_basename)s%(defaults_upper)s"
tag: v5-34-30-alice7
source: https://github.com/alisw/root
requires:
  - AliEn-Runtime:(?!.*ppc64)
  - GSL
  - opengl:(?!osx)
  - Xdevel:(?!osx)
  - FreeType:(?!osx)
  - "MySQL:slc7.*"
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  ROOTSYS: "$ROOT_ROOT"
prepend_path:
  PYTHONPATH: "$ROOTSYS/lib"
incremental_recipe: |
  if [[ $ALICE_DAQ ]]; then
    export ROOTSYS=$BUILDDIR && make ${JOBS+-j$JOBS} && make static
    for S in montecarlo/vmc tree/treeplayer io/xmlparser math/minuit2 sql/mysql; do
      mkdir -p $INSTALLROOT/$S/src
      cp -v $S/src/*.o $INSTALLROOT/$S/src/
    done
    export ROOTSYS=$INSTALLROOT
  fi
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
[[ "$CXXFLAGS" == *'-std=c++11'* ]] && CXX11=1 || true
[[ "$CXXFLAGS" == *'-std=c++14'* ]] && CXX14=1 || true

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

if [[ $ALICE_DAQ ]]; then
  # DAQ requires static ROOT, only supported by ./configure (not CMake).
  export ROOTSYS=$BUILDDIR
  $SOURCEDIR/configure                  \
    --with-pythia6-uscore=SINGLE        \
    --enable-minuit2                    \
    --enable-roofit                     \
    --enable-soversion                  \
    --enable-builtin-freetype           \
    --enable-builtin-pcre               \
    --enable-mathmore                   \
    --with-f77=gfortran                 \
    --with-cc=$COMPILER_CC              \
    --with-cxx=$COMPILER_CXX            \
    --with-ld=$COMPILER_LD              \
    ${CXXFLAGS:+--cxxflags="$CXXFLAGS"} \
    --disable-shadowpw                  \
    --disable-astiff                    \
    --disable-globus                    \
    --disable-krb5                      \
    --disable-ssl                       \
    --enable-mysql
  FEATURES="builtin_freetype builtin_pcre mathmore minuit2 pythia6 roofit
            soversion ${CXX11:+cxx11} ${CXX14:+cxx14} mysql xml"
else
  # Normal ROOT build.
  cmake $SOURCEDIR                                                \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                      \
        -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                       \
        ${ALIEN_RUNTIME_ROOT:+-Dalien=ON}                         \
        ${ALIEN_RUNTIME_ROOT:+-DALIEN_DIR=$ALIEN_RUNTIME_ROOT}    \
        ${ALIEN_RUNTIME_ROOT:+-DMONALISA_DIR=$ALIEN_RUNTIME_ROOT} \
        ${XROOTD_ROOT:+-DXROOTD_ROOT_DIR=$ALIEN_RUNTIME_ROOT}     \
        ${CXX11:+-Dcxx11=ON}                                      \
        ${CXX14:+-Dcxx14=ON}                                      \
        -Dfreetype=ON                                             \
        -Dbuiltin_freetype=OFF                                    \
        -Dpcre=OFF                                                \
        -Dbuiltin_pcre=ON                                         \
        ${ENABLE_COCOA:+-Dcocoa=ON}                               \
        -DCMAKE_CXX_COMPILER=$COMPILER_CXX                        \
        -DCMAKE_C_COMPILER=$COMPILER_CC                           \
        -DCMAKE_LINKER=$COMPILER_LD                               \
        ${GCC_TOOLCHAIN_VERSION:+-DCMAKE_EXE_LINKER_FLAGS="-L$GCC_TOOLCHAIN_ROOT/lib64"} \
        ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$ALIEN_RUNTIME_ROOT}       \
        ${SYS_OPENSSL_ROOT:+-DOPENSSL_ROOT=$SYS_OPENSSL_ROOT}     \
        ${SYS_OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIR=$SYS_OPENSSL_ROOT/include}  \
        ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$ALIEN_RUNTIME_ROOT}       \
        ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                          \
        -Dpgsql=OFF                                               \
        -Dminuit2=ON                                              \
        -Dpythia6_nolink=ON                                       \
        -Droofit=ON                                               \
        -Dhttp=ON                                                 \
        -Dsoversion=ON                                            \
        -Dshadowpw=OFF                                            \
        -Dvdt=ON                                                  \
        -Dbuiltin_vdt=ON                                          \
        -DCMAKE_PREFIX_PATH="$FREETYPE_ROOT;$SYS_OPENSSL_ROOT;$GSL_ROOT;$ALIEN_RUNTIME_ROOT;$PYTHON_ROOT;$PYTHON_MODULES_ROOT"
  FEATURES="builtin_pcre mathmore xml ssl opengl minuit2 http
            pythia6 roofit soversion vdt ${CXX11:+cxx11} ${CXX14:+cxx14} ${XROOTD_ROOT:+xrootd}
            ${ALIEN_RUNTIME_ROOT:+alien monalisa}
            ${ENABLE_COCOA:+builtin_freetype}"
  NO_FEATURES="${FREETYPE_ROOT:+builtin_freetype}"
fi

# Check if all required features are enabled
bin/root-config --features
for FEATURE in $FEATURES; do
  bin/root-config --has-$FEATURE | grep -q yes
done
for FEATURE in $NO_FEATURES; do
  bin/root-config --has-$FEATURE | grep -q no
done

if [[ $ALICE_DAQ ]]; then
  make ${JOBS+-j$JOBS}
  make static
  # *.o files from these modules need to be copied to the install directory
  # because AliRoot static build uses them directly
  for S in montecarlo/vmc tree/treeplayer io/xmlparser math/minuit2 sql/mysql; do
    mkdir -p $INSTALLROOT/$S/src
    cp -v $S/src/*.o $INSTALLROOT/$S/src/
  done
  export ROOTSYS=$INSTALLROOT
fi
make ${JOBS+-j$JOBS} install
[[ -d $INSTALLROOT/test ]] && ( cd $INSTALLROOT/test && env PATH=$INSTALLROOT/bin:$PATH LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH make ${JOBS+-j$JOBS} )

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
module load BASE/1.0 ${ALIEN_RUNTIME_ROOT:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}        \\
                     ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}     \\
                     ${GSL_VERSION:+GSL/$GSL_VERSION-$GSL_REVISION}                                             \\
                     ${FREETYPE_VERSION:+FreeType/$FREETYPE_VERSION-$FREETYPE_REVISION}                         \\
                     ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
                     ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
# Our environment
setenv ROOT_RELEASE \$version
setenv ROOT_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv ROOTSYS \$::env(ROOT_BASEDIR)/\$::env(ROOT_RELEASE)
prepend-path PYTHONPATH \$::env(ROOTSYS)/lib
prepend-path PATH \$::env(ROOTSYS)/bin
prepend-path LD_LIBRARY_PATH \$::env(ROOTSYS)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ROOTSYS)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
