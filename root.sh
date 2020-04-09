package: ROOT
version: "%(tag_basename)s"
tag: "v6-20-02-alice3"
source: https://github.com/alisw/root
requires:
  - arrow
  - AliEn-Runtime:(?!.*ppc64)
  - GSL
  - opengl:(?!osx)
  - Xdevel:(?!osx)
  - FreeType:(?!osx)
  - Python-modules
  - "GCC-Toolchain:(?!osx)"
  - libpng
  - lzma
  - libxml2
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - XRootD
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  ROOTSYS: "$ROOT_ROOT"
prepend_path:
  PYTHONPATH: "$ROOTSYS/lib"
incremental_recipe: |
  # Limit parallel builds to prevent OOM
  JOBS=$((${JOBS:-1}*3/5))
  [[ $JOBS -gt 0 ]] || JOBS=1
  cmake --build . --target install ${JOBS:+-- -j$JOBS}
  rm -vf "$INSTALLROOT/etc/plugins/TGrid/P010_TAlien.C"         \
         "$INSTALLROOT/etc/plugins/TSystem/P030_TAlienSystem.C" \
         "$INSTALLROOT/etc/plugins/TFile/P070_TAlienFile.C"

  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
unset ROOTSYS

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++
case $PKGVERSION in
  v6-20*) 
     ENABLE_VMC=1
     [[ "$CXXFLAGS" == *'-std=c++11'* ]] && CMAKE_CXX_STANDARD=11 || true
     [[ "$CXXFLAGS" == *'-std=c++14'* ]] && CMAKE_CXX_STANDARD=14 || true
     [[ "$CXXFLAGS" == *'-std=c++17'* ]] && CMAKE_CXX_STANDARD=17 || true
  ;;
  *)
    [[ "$CXXFLAGS" == *'-std=c++11'* ]] && CXX11=1 || true
    [[ "$CXXFLAGS" == *'-std=c++14'* ]] && CXX14=1 || true
    [[ "$CXXFLAGS" == *'-std=c++17'* ]] && CXX17=1 || true
  ;;
esac

# We do not use global options for ROOT, otherwise the -g will kill compilation 
# on < 8GB machines
unset CXXFLAGS
unset CFLAGS
unset LDFLAGS

SONAME=so
case $ARCHITECTURE in
  osx*)
    ENABLE_COCOA=1
    DISABLE_MYSQL=1
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    SONAME=dylib
    [[ ! $GSL_ROOT ]] && GSL_ROOT=$(brew --prefix gsl)
    [[ ! $OPENSSL_ROOT ]] && SYS_OPENSSL_ROOT=$(brew --prefix openssl)
    [[ ! $LIBPNG_ROOT ]] && LIBPNG_ROOT=$(brew --prefix libpng)
  ;;
esac

if [[ $ALIEN_RUNTIME_VERSION ]]; then
  # AliEn-Runtime: we take OpenSSL and libxml2 from there, in case they
  # were not taken from the system
  OPENSSL_ROOT=${OPENSSL_ROOT:+$ALIEN_RUNTIME_ROOT}
  LIBXML2_ROOT=${LIBXML2_REVISION:+$ALIEN_RUNTIME_ROOT}
fi
[[ $SYS_OPENSSL_ROOT ]] && OPENSSL_ROOT=$SYS_OPENSSL_ROOT

if [[ -d $SOURCEDIR/interpreter/llvm ]]; then
  # ROOT 6+: enable Python
  ROOT_PYTHON_FLAGS="-Dpyroot=ON"
  ROOT_PYTHON_FEATURES="pyroot"
  ROOT_HAS_PYTHON=1
  # One can explicitly pick a Python version with -DPYTHON_EXECUTABLE=... -DPYTHON_INCLUDE_DIR=<path_to_Python.h>
  PYTHON_EXECUTABLE=$(python3-config --exec-prefix)/bin/python3
  PYTHON_INCLUDE_DIR=$(python3-config --includes | sed -e's/^[ ]*-I//' | cut -f1 -d' ')
  PYTHON_LIBRARY_DIR=$(python3-config --ldflags | sed -e's/^[ ]*-L//' | cut -f1 -d' ')
  PYTHON_LIBNAME=$(python3-config --libs | cut -f1 -d' ' | cut -c3-)
  PYTHON_LIBRARIES=${PYTHON_LIBRARY_DIR}/lib${PYTHON_LIBNAME}.${SONAME}
else
  # Non-ROOT 6 builds: disable Python
  ROOT_PYTHON_FLAGS="-Dpyroot=OFF"
  ROOT_PYTHON_FEATURES=
  ROOT_HAS_NO_PYTHON=1
fi

unset DYLD_LIBRARY_PATH
# Standard ROOT build
cmake $SOURCEDIR                                                                       \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                        \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                              \
      -Dalien=OFF                                                                      \
      ${ALIEN_RUNTIME_REVISION:+-DMONALISA_DIR=$ALIEN_RUNTIME_ROOT}                    \
      ${XROOTD_ROOT:+-DXROOTD_ROOT_DIR=$XROOTD_ROOT}                                   \
      ${CMAKE_CXX_STANDARD:+-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}}                \
      ${CXX11:+-Dcxx11=ON}                                                             \
      ${CXX14:+-Dcxx14=ON}                                                             \
      ${CXX17:+-Dcxx17=ON}                                                             \
      -Dfreetype=ON                                                                    \
      -Dbuiltin_freetype=OFF                                                           \
      -Dpcre=OFF                                                                       \
      -Dbuiltin_pcre=ON                                                                \
      -Dsqlite=OFF                                                                     \
      $ROOT_PYTHON_FLAGS                                                               \
      ${ARROW_ROOT:+-Darrow=ON}                                                        \
      ${ARROW_ROOT:+-DARROW_HOME=$ARROW_ROOT}                                          \
      ${ENABLE_COCOA:+-Dcocoa=ON}                                                      \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                                               \
      -DCMAKE_C_COMPILER=$COMPILER_CC                                                  \
      -Dfortran=OFF                                                                    \
      -DCMAKE_LINKER=$COMPILER_LD                                                      \
      ${GCC_TOOLCHAIN_REVISION:+-DCMAKE_EXE_LINKER_FLAGS="-L$GCC_TOOLCHAIN_ROOT/lib64"} \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$OPENSSL_ROOT}                                    \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIR=$OPENSSL_ROOT/include}                     \
      ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$LIBXML2_ROOT}                                    \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                 \
      ${LIBPNG_ROOT:+-DPNG_INCLUDE_DIRS="${LIBPNG_ROOT}/include"}                      \
      ${LIBPNG_ROOT:+-DPNG_LIBRARY="${LIBPNG_ROOT}/lib/libpng.${SONAME}"}              \
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
      ${ALIEN_RUNTIME_REVISION:+-Dmonalisa=ON}                                         \
      -Dkrb5=OFF                                                                       \
      -Dgviz=OFF                                                                       \
      -Dbuiltin_davix=OFF                                                              \
      ${ENABLE_VMC:+-Dvmc=ON}                                                          \
      -Ddavix=OFF                                                                      \
      ${DISABLE_MYSQL:+-Dmysql=OFF}                                                    \
      ${ROOT_HAS_PYTHON:+-DPYTHON_PREFER_VERSION=3}                                    \
      ${ROOT_HAS_PYTHON:+-DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}}                     \
      ${ROOT_HAS_PYTHON:+-DPYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}}                   \
      ${ROOT_HAS_PYTHON:+-DPYTHON_LIBRARIES=${PYTHON_LIBRARIES}}                       \
      ${ROOT_HAS_PYTHON:+-DPython_EXECUTABLE=${PYTHON_EXECUTABLE}}                     \
      ${ROOT_HAS_PYTHON:+-DPython_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}}                   \
      ${ROOT_HAS_PYTHON:+-DPython_INCLUDE_DIRS=${PYTHON_INCLUDE_DIR}}                  \
      ${ROOT_HAS_PYTHON:+-DPYTHON_LIBRARIES=${PYTHON_LIBRARIES}}                       \
-DCMAKE_PREFIX_PATH="$FREETYPE_ROOT;$SYS_OPENSSL_ROOT;$GSL_ROOT;$ALIEN_RUNTIME_ROOT;$PYTHON_ROOT;$PYTHON_MODULES_ROOT;$LIBPNG_ROOT;$LZMA_ROOT"
FEATURES="builtin_pcre mathmore xml ssl opengl minuit2 http
          pythia6 roofit soversion vdt ${CXX11:+cxx11} ${CXX14:+cxx14} ${CXX17:+cxx17}
          ${XROOTD_ROOT:+xrootd} ${ALIEN_RUNTIME_ROOT:+monalisa} ${ROOT_HAS_PYTHON:+pyroot}
          ${ARROW_REVISION:+arrow}"
NO_FEATURES="root7 ${LZMA_REVISION:+builtin_lzma} ${LIBPNG_REVISION:+builtin_png} krb5 gviz
             ${ROOT_HAS_NO_PYTHON:+pyroot} builtin_davix davix alien"

if [[ $ENABLE_COCOA ]]; then
  FEATURES="$FEATURES builtin_freetype"
elif [[ $FREETYPE_ROOT ]]; then
  NO_FEATURES="$NO_FEATURES builtin_freetype"
fi

# Check if all important features are enabled/disabled as requested
bin/root-config --features
for FEATURE in $FEATURES; do
  bin/root-config --has-$FEATURE | grep -q yes
done
for FEATURE in $NO_FEATURES; do
  bin/root-config --has-$FEATURE | grep -q no
done

# Limit parallel builds to prevent OOM
JOBS=$((${JOBS:-1}*3/5))
[[ $JOBS -gt 0 ]] || JOBS=1
cmake --build . --target install ${JOBS:+-- -j$JOBS}

# Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
grep -v '^Unix.*.Root.PluginPath' $INSTALLROOT/etc/system.rootrc > system.rootrc.0
cat >> system.rootrc.0 <<EOF

# Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
# Plugins in \$ROOT_PLUGIN_PATH have priority.
Unix.*.Root.PluginPath: \$(ROOT_PLUGIN_PATH):\$(ROOTSYS)/etc/plugins:
Unix.*.Root.DynamicPath: .:\$(ROOT_DYN_PATH):
EOF
mv system.rootrc.0 $INSTALLROOT/etc/system.rootrc

if [[ $ALIEN_RUNTIME_VERSION ]]; then
  # Get them from AliEn-Runtime in the Modulefile
  unset OPENSSL_VERSION LIBXML2_VERSION OPENSSL_REVISION LIBXML2_REVISION
fi

# Make some CMake files used by other projects relocatable
sed -i.deleteme -e "s!$BUILDDIR!$INSTALLROOT!g" $(find "$INSTALLROOT" -name '*.cmake') || true

rm -vf "$INSTALLROOT/etc/plugins/TGrid/P010_TAlien.C"         \
       "$INSTALLROOT/etc/plugins/TSystem/P030_TAlienSystem.C" \
       "$INSTALLROOT/etc/plugins/TFile/P070_TAlienFile.C"     \
       "$INSTALLROOT/LICENSE"

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
module load BASE/1.0 ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}     \\
                     ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}                             \\
                     ${XROOTD_REVISION:+XRootD/$XROOTD_VERSION-$XROOTD_REVISION}                                 \\
                     ${LIBXML2_REVISION:+libxml2/$LIBXML2_VERSION-$LIBXML2_REVISION}                             \\
                     ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}     \\
                     ${GSL_REVISION:+GSL/$GSL_VERSION-$GSL_REVISION}                                             \\
                     ${FREETYPE_REVISION:+FreeType/$FREETYPE_VERSION-$FREETYPE_REVISION}                         \\
                     ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
                     ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} \\
                     ${ARROW_REVISION:+arrow/$ARROW_VERSION-$ARROW_REVISION}                                     \\
                     ${LIBPNG_REVISION:+libpng/$LIBPNG_VERSION-$LIBPNG_REVISION}                                 \\
                     ${LZMA_REVISION:+lzma/$LZMA_VERSION-$LZMA_REVISION}
# Our environment
setenv ROOT_RELEASE \$version
setenv ROOT_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv ROOTSYS \$::env(ROOT_BASEDIR)/\$::env(ROOT_RELEASE)

set ROOT_ROOT  \$::env(ROOTSYS)
prepend-path PYTHONPATH \$ROOT_ROOT/lib
prepend-path PATH \$ROOT_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ROOT_ROOT/lib
prepend-path ROOT_DYN_PATH \$ROOT_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
