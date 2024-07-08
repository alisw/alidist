package: ROOT
version: "%(tag_basename)s"
tag: "v6-30-01-alice5"
source: https://github.com/alisw/root.git
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
  - TBB
  - protobuf
  - FFTW3
  - Vc
  - pythia
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
  - ninja
env:
  ROOTSYS: "$ROOT_ROOT"
prepend_path:
  PYTHONPATH: "$ROOTSYS/lib"
  ROOT_DYN_PATH: "$ROOT_ROOT/lib"
incremental_recipe: |
  # Limit parallel builds to prevent OOM
  cmake --build . --target install ${JOBS+-j $JOBS}
  rm -vf "$INSTALLROOT/etc/plugins/TGrid/P010_TAlien.C"         \
         "$INSTALLROOT/etc/plugins/TSystem/P030_TAlienSystem.C" \
         "$INSTALLROOT/etc/plugins/TFile/P070_TAlienFile.C"
  # Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
  grep -v '^Unix.*.Root.PluginPath' "$INSTALLROOT/etc/system.rootrc" > system.rootrc.0
  cat >> system.rootrc.0 <<\EOF
  # Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
  # Plugins in \$ROOT_PLUGIN_PATH have priority.
  Unix.*.Root.PluginPath: $(ROOT_PLUGIN_PATH):$(ROOTSYS)/etc/plugins:
  Unix.*.Root.DynamicPath: .:$(ROOT_DYN_PATH):
  EOF
  mv system.rootrc.0 "$INSTALLROOT/etc/system.rootrc"

  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
# Fix the syntax highlighing when your editor is not smart enough to 
# understand yaml.
cat >/dev/null <<EOF
EOF

unset ROOTSYS
COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++
[[ "$CXXFLAGS" == *'-std=c++11'* ]] && CMAKE_CXX_STANDARD=11 || true
[[ "$CXXFLAGS" == *'-std=c++14'* ]] && CMAKE_CXX_STANDARD=14 || true
[[ "$CXXFLAGS" == *'-std=c++17'* ]] && CMAKE_CXX_STANDARD=17 || true
[[ "$CXXFLAGS" == *'-std=c++20'* ]] && CMAKE_CXX_STANDARD=20 || true

# We do not use global options for ROOT, otherwise the -g will
# kill compilation on < 8GB machines
unset CXXFLAGS
unset CFLAGS
unset LDFLAGS

SONAME=so
case $ARCHITECTURE in
  osx*)
    ENABLE_COCOA=1
    DISABLE_MYSQL=1
    USE_BUILTIN_GLEW=1
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    SONAME=dylib
    [[ ! $GSL_ROOT ]] && GSL_ROOT=$(brew --prefix gsl)
    [[ ! $OPENSSL_ROOT ]] && SYS_OPENSSL_ROOT=$(brew --prefix openssl@3)
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

# ROOT 6+: enable Python
ROOT_PYTHON_FLAGS="-Dpyroot=ON"
ROOT_HAS_PYTHON=1
python_exec=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_config_var("exec_prefix"))')/bin/python3
if [ "$python_exec" = "$(which python3)" ]; then
  # By default, if there's nothing funny going on, let ROOT pick the Python in
  # the PATH, which is the one built by us (unless disabled, in which case it
  # is the system one). This is substituted into ROOT's Python scripts'
  # shebang lines, so we cannot use an absolute path because the path to our
  # Python will differ between build time and runtime, e.g. on the Grid.
  PYTHON_EXECUTABLE=
else
  # If Python's exec_prefix doesn't point to the same place as $PATH, then we
  # have a shim script in between. This is used by things like pyenv and asdf.
  # This doesn't happen when building things to be published, only in local
  # usage, so hardcoding an absolute path into the shebangs is fine.
  PYTHON_EXECUTABLE=$python_exec
fi

if [ -n "$XROOTD_ROOT" ]; then
  ROOT_XROOTD_FLAGS="-Dxrootd=ON -DXROOTD_ROOT_DIR=$XROOTD_ROOT"
else
  # If we didn't build XRootD (e.g. if it was disabled by a default), explicitly
  # disable support for it -- otherwise, ROOT will download and compile against
  # its own XRootD version.
  ROOT_XROOTD_FLAGS='-Dxrootd=OFF'
fi

case $PKG_VERSION in
  v6[-.]30*) EXTRA_CMAKE_OPTIONS="-Dminuit2=ON -Dpythia6=ON -Dpythia6_nolink=ON" ;;
  *) EXTRA_CMAKE_OPTIONS="-Dminuit=ON" ;;
esac

unset DYLD_LIBRARY_PATH
CMAKE_GENERATOR=${CMAKE_GENERATOR:-Ninja}
# Standard ROOT build
cmake $SOURCEDIR                                                                       \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                        \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                              \
      -Dalien=OFF                                                                      \
      ${CMAKE_CXX_STANDARD:+-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}}                \
      -Dfreetype=ON                                                                    \
      -Dbuiltin_freetype=OFF                                                           \
      -Dpcre=OFF                                                                       \
      -Dbuiltin_pcre=ON                                                                \
      -Dsqlite=OFF                                                                     \
      $ROOT_XROOTD_FLAGS                                                               \
      $ROOT_PYTHON_FLAGS                                                               \
      ${ARROW_ROOT:+-Darrow=ON}                                                        \
      ${ARROW_ROOT:+-DARROW_HOME=$ARROW_ROOT}                                          \
      ${ENABLE_COCOA:+-Dcocoa=ON}                                                      \
      ${EXTRA_CMAKE_OPTIONS}                                                           \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                                               \
      -DCMAKE_C_COMPILER=$COMPILER_CC                                                  \
      -Dfortran=OFF                                                                    \
      -DCMAKE_LINKER=$COMPILER_LD                                                      \
      ${GCC_TOOLCHAIN_REVISION:+-DCMAKE_EXE_LINKER_FLAGS="-L$GCC_TOOLCHAIN_ROOT/lib64"} \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT=$OPENSSL_ROOT}                                    \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIR=$OPENSSL_ROOT/include}                     \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME}  \
      ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$LIBXML2_ROOT}                                    \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                 \
      ${LIBPNG_ROOT:+-DPNG_INCLUDE_DIRS="${LIBPNG_ROOT}/include"}                      \
      ${LIBPNG_ROOT:+-DPNG_LIBRARY="${LIBPNG_ROOT}/lib/libpng.${SONAME}"}              \
      ${PROTOBUF_REVISION:+-DProtobuf_DIR=${PROTOBUF_ROOT}}                            \
      ${ZLIB_ROOT:+-DZLIB_ROOT=${ZLIB_ROOT}}                                           \
      ${FFTW3_ROOT:+-DFFTW_DIR=${FFTW3_ROOT}}                                          \
      -Dfftw3=ON                                                                       \
      -Dpgsql=OFF                                                                      \
      -Dminuit=ON                                                                     \
      -Dmathmore=ON                                                                    \
      -Droofit=ON                                                                      \
      -Dhttp=ON                                                                        \
      -Droot7=OFF                                                                      \
      -Dsoversion=ON                                                                   \
      -Dshadowpw=OFF                                                                   \
      -Dvdt=OFF                                                                        \
      -Dvc=ON                                                                          \
      -Dbuiltin_vc=OFF                                                                 \
      -Dbuiltin_vdt=OFF                                                                \
      -Dgviz=OFF                                                                       \
      -Dbuiltin_davix=OFF                                                              \
      -Dbuiltin_afterimage=ON                                                          \
      -Dbuiltin_fftw3=OFF                                                              \
      -Dtmva-sofie=ON                                                                  \
      -Dtmva-gpu=OFF                                                                   \
      -Ddavix=OFF                                                                      \
      -Dunfold=ON                                                                      \
      -Dpythia8=ON                                                                     \
      ${USE_BUILTIN_GLEW:+-Dbuiltin_glew=ON}                                           \
      ${DISABLE_MYSQL:+-Dmysql=OFF}                                                    \
      ${ROOT_HAS_PYTHON:+-DPYTHON_PREFER_VERSION=3}                                    \
      ${PYTHON_EXECUTABLE:+-DPYTHON_EXECUTABLE="${PYTHON_EXECUTABLE}"}                 \
-DCMAKE_PREFIX_PATH="$FREETYPE_ROOT;$SYS_OPENSSL_ROOT;$GSL_ROOT;$ALIEN_RUNTIME_ROOT;$PYTHON_ROOT;$PYTHON_MODULES_ROOT;$LIBPNG_ROOT;$LZMA_ROOT;$PROTOBUF_ROOT;$FFTW3_ROOT"

# Workaround issue with cmake 3.29.0
sed -i.removeme '/deps = gcc/d' build.ninja
rm *.removeme
cmake --build . --target install ${JOBS+-j $JOBS}

# Make sure ROOT actually found its build dependencies and didn't disable
# features we requested. "-Dfail-on-missing=ON" would probably be better.
[ "$("$INSTALLROOT/bin/root-config" --has-fftw3)" = yes ]

# Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
grep -v '^Unix.*.Root.PluginPath' $INSTALLROOT/etc/system.rootrc > system.rootrc.0
cat >> system.rootrc.0 <<\EOF
# Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
# Plugins in $ROOT_PLUGIN_PATH have priority.
Unix.*.Root.PluginPath: $(ROOT_PLUGIN_PATH):$(ROOTSYS)/etc/plugins:
Unix.*.Root.DynamicPath: .:$(ROOT_DYN_PATH):
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

# Make sure all the tools use the correct python
for binfile in "$INSTALLROOT"/bin/*; do
  [ -f "$binfile" ] || continue
  if grep -q "^'''exec' .*python.*" "$binfile"; then
    # This file uses a hack to get around shebang size limits. As we're
    # replacing the shebang with the system python, the limit doesn't apply and
    # we can just use a normal shebang.
    sed -i.bak '1d; 2d; 3d; 4s,^,#!/usr/bin/env python3\n,' "$binfile"
  else
    sed -i.bak '1s,^#!.*python.*,#!/usr/bin/env python3,' "$binfile"
  fi
done
rm -fv "$INSTALLROOT"/bin/*.bak

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
setenv ROOT_RELEASE \$version
setenv ROOT_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv ROOTSYS \$::env(ROOT_BASEDIR)/\$::env(ROOT_RELEASE)
prepend-path PYTHONPATH \$PKG_ROOT/lib
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

# External RPM dependencies
cat > $INSTALLROOT/.rpm-extra-deps <<EoF
glibc-headers
EoF
