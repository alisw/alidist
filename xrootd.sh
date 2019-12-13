package: XRootD
version: "%(tag_basename)s"
tag: v3.3.6-alice2
source: https://github.com/alisw/xrootd.git
requires:
 - "OpenSSL:(?!osx)"
 - Python-modules
 - AliEn-Runtime
build_requires:
 - CMake
 - "osx-system-openssl:(osx.*)"
 - libxml2
 - "GCC-Toolchain:(?!osx)"
 - UUID
---
#!/bin/bash -e
[[ -e $SOURCEDIR/bindings ]] && XROOTD_V4=True && XROOTD_PYTHON=True || XROOTD_PYTHON=False
PYTHON_EXECUTABLE=$( $(realpath $(which python3)) -c 'import sys; print(sys.executable)')

case $ARCHITECTURE in
  osx*)
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl)
    MACOS_SYSROOT="$(find `xcode-select -p` -type d -path *usr/include/c++)"
    PYTHON_EXECUTABLE="CFLAGS=\"${MACOS_SYSROOT}\" ${PYTHON_EXECUTABLE}"
  ;;
esac

cmake "$SOURCEDIR"                                             \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                      \
      -DCMAKE_INSTALL_LIBDIR=lib                               \
      -DENABLE_CRYPTO=ON                                       \
      -DENABLE_PERL=OFF                                        \
      ${XROOTD_PYTHON:+-DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE} \
      -DENABLE_KRB5=OFF                                        \
      -DENABLE_READLINE=OFF                                    \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                        \
      ${UUID_ROOT:+-DUUID_ROOT=$UUID_ROOT}                      \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}        \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                     \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS:+-j$JOBS} install

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
module load BASE/1.0 \
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}     \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}                             \\
            ${LIBXML2_REVISION:+libxml2/$LIBXML2_VERSION-$LIBXML2_REVISION}                             \\
            ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}

# Our environment
set XROOTD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv XROOTD_ROOT \$XROOTD_ROOT
prepend-path PATH \$XROOTD_ROOT/bin
prepend-path LD_LIBRARY_PATH \$XROOTD_ROOT/lib
if { $XROOTD_PYTHON } {
  prepend-path PYTHONPATH \$XROOTD_ROOT/lib/python3.6/site-packages
  module load ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
              ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
}
EoF
