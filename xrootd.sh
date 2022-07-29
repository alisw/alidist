package: XRootD
version: "%(tag_basename)s"
tag: "v5.4.3"
source: https://github.com/xrootd/xrootd
requires:
 - "OpenSSL:(?!osx)"
 - Python-modules:(?!osx_arm64)
 - libxml2
 - AliEn-Runtime
build_requires:
 - CMake
 - "osx-system-openssl:(osx.*)"
 - "GCC-Toolchain:(?!osx)"
 - UUID:(?!osx)
 - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: "${XROOTD_ROOT}/lib/python/site-packages"
---
#!/bin/bash -e

if [[ $ALIEN_RUNTIME_VERSION ]]; then
  # AliEn-Runtime: we take libxml2 from there, in case they were not taken from the system
  LIBXML2_ROOT=${LIBXML2_REVISION:+$ALIEN_RUNTIME_ROOT}
fi

XROOTD_PYTHON=""
[[ -e ${SOURCEDIR}/bindings ]] && XROOTD_PYTHON=True;
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

rsync -a --delete ${SOURCEDIR}/ ${BUILDDIR}

mkdir build
pushd build
cmake "${BUILDDIR}"                                                   \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                       \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}                           \
      ${CMAKE_FRAMEWORK_PATH+-DCMAKE_FRAMEWORK_PATH=$CMAKE_FRAMEWORK_PATH} \
      -DCMAKE_INSTALL_LIBDIR=lib                                      \
      -DENABLE_CRYPTO=ON                                              \
      -DENABLE_PERL=OFF                                               \
      -DVOMSXRD_SUBMODULE=OFF                                         \
      ${UUID_ROOT:+-DUUID_LIBRARIES=$UUID_ROOT/lib/libuuid.so}        \
      ${UUID_ROOT:+-DUUID_LIBRARY=$UUID_ROOT/lib/libuuid.so}          \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIRS=$UUID_ROOT/include}            \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIR=$UUID_ROOT/include}             \
      ${LIBXML2_ROOT:+-DLIBXML2_INCLUDE_DIR=$LIBXML2_ROOT/include/libxml2}    \
      ${LIBXML2_ROOT:+-DLIBXML2_LIBRARY=$LIBXML2_ROOT/lib/libxml2.so}         \
      ${LIBXML2_ROOT:+-DLIBXML2_XMLLINT_EXECUTABLE=$LIBXML2_ROOT/bin/xmllint} \
      -DENABLE_KRB5=OFF                                               \
      -DENABLE_READLINE=OFF                                           \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                               \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}               \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                            \
      ${XROOTD_PYTHON:+-DENABLE_PYTHON=ON}                                        \
      ${XROOTD_PYTHON:+-DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE}                    \
      ${XROOTD_PYTHON:+-DXROOTD_PYBUILD_ENV='CC=c++ CFLAGS=\"-std=c++17\"'}       \
      ${XROOTD_PYTHON:+-DPIP_OPTIONS='--force-reinstall --ignore-installed -v'}   \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS:+-j$JOBS} install
popd

if [[ x"$XROOTD_PYTHON" == x"True" ]]; then
    pushd $INSTALLROOT

    # there are cases where python bindings are installed as relative to INSTALLROOT
    if [[ -d local/lib64 ]]; then
        [[ -d local/lib64/python${PYTHON_VER} ]] && mv -f local/lib64/python${PYTHON_VER} lib/
    fi
    if [[ -d local/lib ]]; then
        [[ -d local/lib/python${PYTHON_VER} ]] && mv -f local/lib/python${PYTHON_VER} lib/
    fi

    pushd lib
    if [[ -d ../lib64/python${PYTHON_VER} ]]; then
      ln -s ../lib64/python${PYTHON_VER} python
    elif [[ -d python${PYTHON_VER} ]]; then
      ln -s python${PYTHON_VER} python
    fi
    [[ ! -e python ]] && echo "NO PYTHON DIRECTORY FOUND in $(pwd -P)"
    popd

    popd

  case $ARCHITECTURE in
    osx*)
      find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
      find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
    ;;
  esac

    # Print found XRootD python bindings
    if [[ -d ${INSTALLROOT}/lib/python${PYTHON_VER} ]]; then
        echo "Printing found XRootD python bindings"
        LD_LIBRARY_PATH="$INSTALLROOT/lib${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH" PYTHONPATH="$INSTALLROOT/lib/python/site-packages${PYTHONPATH:+:}$PYTHONPATH" ${PYTHON_EXECUTABLE} -c 'from XRootD import client as xrd_client;print(f"{xrd_client.__version__}\n{xrd_client.__file__}");'
        echo "END of printing XRootD python bindings info"
    else
        echo "NO PYTHON BINDINGS DIRECTORY FOUND!!!"
        exit 1
    fi
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
