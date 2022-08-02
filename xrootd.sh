package: XRootD
version: "%(tag_basename)s"
tag: "v5.4.3"
source: https://github.com/xrootd/xrootd
requires:
 - "OpenSSL:(?!osx)"
 - Python-modules:(?!osx_arm64)
 - AliEn-Runtime
 - libxml2
build_requires:
 - CMake
 - "osx-system-openssl:(osx.*)"
 - "GCC-Toolchain:(?!osx)"
 - UUID:(?!osx)
 - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: "$XROOTD_ROOT/lib/python/site-packages"
---
#!/bin/bash -e
[[ -e $SOURCEDIR/bindings ]] && { XROOTD_V4=True; XROOTD_PYTHON=True; } || XROOTD_PYTHON=False
PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
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
  osx_arm64)
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@1.1)
    CMAKE_FRAMEWORK_PATH=$(brew --prefix)/Frameworks

    # NOTE: Python from Homebrew will have a hardcoded sysroot pointing to Xcode.app directory wchich might not exist.
    # This seems to be a robust way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    export CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    unset UUID_ROOT
    if [ "$(python3 -c 'import setuptools; print(setuptools.__version__)')" != "60.8.2" ]; then
      echo 'Please install setuptools==60.8.2'
      exit 1
    fi
  ;;
esac

rsync -a --delete $SOURCEDIR/ $BUILDDIR

mkdir build
pushd build
cmake "$BUILDDIR"                                                     \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                       \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                             \
      ${CMAKE_FRAMEWORK_PATH+-DCMAKE_FRAMEWORK_PATH=$CMAKE_FRAMEWORK_PATH} \
      -DCMAKE_INSTALL_LIBDIR=lib                                      \
      -DXRDCL_ONLY=ON                                                 \
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
      -DXROOTD_PYBUILD_ENV='CC=c++ CFLAGS=\"-std=c++17\"'             \
      -DPIP_OPTIONS='--force-reinstall --ignore-installed'            \
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
  case $ARCHITECTURE in
    osx*)
      find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
      find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
    ;;
  esac
fi


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
