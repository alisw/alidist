package: XRootD
version: "%(tag_basename)s"
tag: "v5.4.2-alice1"
source: https://github.com/alisw/xrootd
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
 - alibuild-recipe-tools
---
#!/bin/bash -e
[[ -e $SOURCEDIR/bindings ]] && { XROOTD_V4=True; XROOTD_PYTHON=True; } || XROOTD_PYTHON=False
PYTHON_EXECUTABLE=$( $(realpath $(command which python3)) -c 'import sys; print(sys.executable)' )
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )

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

if [ x"$XROOTD_V4" = x"True" ]; then
    sed -i.bak 's/"uuid.h"/"uuid\/uuid.h"/' $(find . -name "*Macaroon*Handler*.cc")
    sed -i.bak '/^\s*--force-reinstall \\/s/--force-reinstall/--force-reinstall --ignore-installed/' "${BUILDDIR}/bindings/python/CMakeLists.txt"
fi

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
      ln -s ../lib64/python${PYTHON_VER} python
    else
      ln -s python${PYTHON_VER} python
    fi
    popd
  popd
fi

case $ARCHITECTURE in
  osx*)
    find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
    find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
  ;;
esac

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin --lib > "$MODULEFILE"

cat >> "$MODULEFILE" <<EoF
if { $XROOTD_PYTHON } {
  prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
  # This is probably redundant, but should not harm.
  module load ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
              ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
}
EoF
