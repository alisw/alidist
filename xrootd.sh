package: XRootD
version: "%(tag_basename)s"
tag: "v5.3.3"
source: https://github.com/xrootd/xrootd
requires:
 - "OpenSSL:(?!osx)"
 - Python-modules
 - AliEn-Runtime
 - libxml2
build_requires:
 - CMake
 - "osx-system-openssl:(osx.*)"
 - "GCC-Toolchain:(?!osx)"
 - UUID:(?!osx)
---
#!/bin/bash -e
[[ -e $SOURCEDIR/bindings ]] && XROOTD_V4=True && XROOTD_PYTHON=True || XROOTD_PYTHON=False
PYTHON_EXECUTABLE=$( $(realpath $(which python3)) -c 'import sys; print(sys.executable)')

case $ARCHITECTURE in
  osx_x86-64)
    export ARCHFLAGS="-arch x86_64"
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@1.1)

    # NOTE: Python from Homebrew will have a hardcoded sysroot pointing to Xcode.app directory wchich might not exist.
    # This seems to be a robust way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    export CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    unset UUID_ROOT
  ;;
  osx*)
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@1.1)

    # NOTE: Python from Homebrew will have a hardcoded sysroot pointing to Xcode.app directory wchich might not exist.
    # This seems to be a robust way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    export CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    unset UUID_ROOT
  ;;
esac

rsync -a --delete $SOURCEDIR/ $BUILDDIR

[ x"$XROOTD_V4" = x"True" ] && sed -i.bak 's/"uuid.h"/"uuid\/uuid.h"/' $(find . -name "*Macaroon*Handler*.cc")


mkdir build
pushd build
cmake "$BUILDDIR"                                                     \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                       \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                             \
      -DCMAKE_INSTALL_LIBDIR=lib                                      \
      -DENABLE_CRYPTO=ON                                              \
      -DENABLE_PERL=OFF                                               \
      -DVOMSXRD_SUBMODULE=OFF                                         \
      ${XROOTD_PYTHON:+-DENABLE_PYTHON=ON}                            \
      ${XROOTD_PYTHON:+-DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE}        \
      ${UUID_ROOT:+-DUUID_LIBRARIES=$UUID_ROOT/lib/libuuid.so}        \
      ${UUID_ROOT:+-DUUID_LIBRARY=$UUID_ROOT/lib/libuuid.so}          \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIRS=$UUID_ROOT/include}            \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIR=$UUID_ROOT/include}             \
      -DENABLE_KRB5=OFF                                               \
      -DENABLE_READLINE=OFF                                           \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                               \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}               \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                            \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS:+-j$JOBS} install
popd

if [[ x"$XROOTD_PYTHON" == x"True" ]];
then
  pushd $INSTALLROOT
    pushd lib
    if [ -d ../lib64 ]; then
      ln -s ../lib64/python* python
    else
      ln -s python* python
    fi
    popd
  popd
fi

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
prepend-path PATH \$XROOTD_ROOT/bin
prepend-path LD_LIBRARY_PATH \$XROOTD_ROOT/lib
if { $XROOTD_PYTHON } {
  prepend-path PYTHONPATH \${XROOTD_ROOT}/lib/python/site-packages
  module load ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
              ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
}
EoF
