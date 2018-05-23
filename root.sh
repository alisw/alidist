package: ROOT
version: "%(tag_basename)s"
tag: v5-34-30-alice10
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
    [[ ! $GSL_ROOT ]] && GSL_ROOT=$(brew --prefix gsl)
    [[ ! $OPENSSL_ROOT ]] && SYS_OPENSSL_ROOT=$(brew --prefix openssl)
  ;;
esac

if [[ $ALIEN_RUNTIME_VERSION ]]; then
  # AliEn-Runtime: we take OpenSSL, XRootD and libxml2 from there, in case they
  # were not taken from the system
  OPENSSL_ROOT=${OPENSSL_ROOT:+$ALIEN_RUNTIME_ROOT}
  XROOTD_ROOT=${XROOTD_VERSION:+$ALIEN_RUNTIME_ROOT}
  LIBXML2_ROOT=${LIBXML2_VERSION:+$ALIEN_RUNTIME_ROOT}
  [[ $SYS_OPENSSL_ROOT ]] && OPENSSL_ROOT=$SYS_OPENSSL_ROOT
fi

# Disable Python for non-ROOT 6 builds
[[ -d $SOURCEDIR/interpreter/llvm ]] || NO_PYTHON=1
[[ $(python  'import sys; sys.exit(0 if sys.version_info[0] > 2 else 1)') -eq 0 ]] && [[ ! $NO_PYTHON ]] && IS_PYTHON3=1

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
    --disable-python                    \
    --disable-alien                     \
    --enable-mysql
  FEATURES="builtin_freetype builtin_pcre minuit2 pythia6 roofit
            soversion ${CXX11:+cxx11} ${CXX14:+cxx14} mysql xml"
  NO_FEATURES="ssl alien"
else
  # Normal ROOT build.
  cmake $SOURCEDIR                                                                       \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                                             \
        -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                              \
        ${ALIEN_RUNTIME_VERSION:+-Dalien=ON}                                             \
        ${ALIEN_RUNTIME_VERSION:+-DALIEN_DIR=$ALIEN_RUNTIME_ROOT}                        \
        ${ALIEN_RUNTIME_VERSION:+-DMONALISA_DIR=$ALIEN_RUNTIME_ROOT}                     \
        ${XROOTD_ROOT:+-DXROOTD_ROOT_DIR=$XROOTD_ROOT}                                   \
        ${CXX11:+-Dcxx11=ON}                                                             \
        ${CXX14:+-Dcxx14=ON}                                                             \
        -Dfreetype=ON                                                                    \
        -Dbuiltin_freetype=OFF                                                           \
        -Dpcre=OFF                                                                       \
        -Dbuiltin_pcre=ON                                                                \
        ${NO_PYTHON:+-Dpython=OFF}                                                       \
        ${IS_PYTHON3:+-Dpython3=ON}                                                      \
        ${ENABLE_COCOA:+-Dcocoa=ON}                                                      \
        -DCMAKE_CXX_COMPILER=$COMPILER_CXX                                               \
        -DCMAKE_C_COMPILER=$COMPILER_CC                                                  \
        -DCMAKE_Fortran_COMPILER=gfortran                                                \
        -DCMAKE_LINKER=$COMPILER_LD                                                      \
        ${GCC_TOOLCHAIN_VERSION:+-DCMAKE_EXE_LINKER_FLAGS="-L$GCC_TOOLCHAIN_ROOT/lib64"} \
        ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$OPENSSL_ROOT}                                    \
        ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIR=$OPENSSL_ROOT/include}                     \
        ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$LIBXML2_ROOT}                                    \
        ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                 \
        ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                 \
        -Dpgsql=OFF                                                                      \
        -Dminuit2=ON                                                                     \
        -Dpythia6_nolink=ON                                                              \
        -Droofit=ON                                                                      \
        -Dhttp=ON                                                                        \
        -Droot7=OFF                                                                      \
        -Dsoversion=ON                                                                   \
        -Dshadowpw=OFF                                                                   \
        -Dvdt=ON                                                                         \
        -Dbuiltin_vdt=ON                                                                 \
        ${ALIEN_RUNTIME_VERSION:+-Dmonalisa=ON}                                          \
        -Dkrb5=OFF                                                                       \
        -Dgviz=OFF                                                                       \
        -DCMAKE_PREFIX_PATH="$FREETYPE_ROOT;$SYS_OPENSSL_ROOT;$GSL_ROOT;$ALIEN_RUNTIME_ROOT;$PYTHON_ROOT;$PYTHON_MODULES_ROOT;$LIBPNG_ROOT;$LZMA_ROOT"
  FEATURES="builtin_pcre mathmore xml ssl opengl minuit2 http
            pythia6 roofit soversion vdt ${CXX11:+cxx11} ${CXX14:+cxx14} ${XROOTD_ROOT:+xrootd}
            ${ALIEN_RUNTIME_ROOT:+alien monalisa} ${IS_PYTHON3:+python python3}"
  NO_FEATURES="root7 ${LZMA_VERSION:+builtin_lzma} ${LIBPNG_VERSION:+builtin_png} krb5 gviz ${NO_PYTHON:+python python3}"

  if [[ $ENABLE_COCOA ]]; then
    FEATURES="$FEATURES builtin_freetype"
  elif [[ $FREETYPE_ROOT ]]; then
    NO_FEATURES="$NO_FEATURES builtin_freetype"
  fi
fi

# Check if all important features are enabled/disabled as requested
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

# Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
grep -v '^Unix.*.Root.PluginPath' $INSTALLROOT/etc/system.rootrc > system.rootrc.0
cat >> system.rootrc.0 <<EOF

# Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
# Plugins in \$ROOT_PLUGIN_PATH have priority.
Unix.*.Root.PluginPath: \$(ROOTSYS)/etc/plugins:\$(ROOT_PLUGIN_PATH)
EOF
mv system.rootrc.0 $INSTALLROOT/etc/system.rootrc

if [[ $ALIEN_RUNTIME_VERSION ]]; then
  # Get them from AliEn-Runtime in the Modulefile
  unset OPENSSL_VERSION XROOTD_VERSION LIBXML2_VERSION
fi

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
module load BASE/1.0 ${ALIEN_RUNTIME_VERSION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}     \\
                     ${OPENSSL_VERSION:+OpenSSL/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}                 \\
                     ${XROOTD_VERSION:+XRootD/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}                   \\
                     ${LIBXML2_VERSION:+libxml2/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}                 \\
                     ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}     \\
                     ${GSL_VERSION:+GSL/$GSL_VERSION-$GSL_REVISION}                                             \\
                     ${FREETYPE_VERSION:+FreeType/$FREETYPE_VERSION-$FREETYPE_REVISION}                         \\
                     ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
                     ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} \\
                     ${LIBPNG_VERSION:+libpng/$LIBPNG_VERSION-$LIBPNG_REVISION}                                 \\
                     ${LZMA_VERSION:+lzma/$LZMA_VERSION-$LZMA_REVISION}
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
