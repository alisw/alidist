package: XRootD
version: "%(tag_basename)s"
tag: "v5.5.3"
source: https://github.com/xrootd/xrootd
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - zlib
  - libxml2
  - AliEn-CAs
  - UUID:(?!osx)
  - Python-modules:(?!osx_arm64)
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
prepend_path:
  PYTHONPATH: "${XROOTD_ROOT}/lib/python/site-packages"
---
#!/bin/bash -e

XROOTD_PYTHON=""
[[ -e ${SOURCEDIR}/bindings ]] && XROOTD_PYTHON=True;
PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )

case $ARCHITECTURE in
  osx_x86-64)
    export ARCHFLAGS="-arch x86_64"
    [[ -z "${OPENSSL_ROOT}" ]] && OPENSSL_ROOT="$(brew --prefix openssl@1.1)"

    # NOTE: Python from Homebrew will have a hardcoded sysroot pointing to Xcode.app directory wchich might not exist.
    # This seems to be a robust way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    export CFLAGS
    unset UUID_ROOT
  ;;
  osx_arm64)
    [[ -z "${OPENSSL_ROOT}" ]] && OPENSSL_ROOT="$(brew --prefix openssl@1.1)"
    CMAKE_FRAMEWORK_PATH="$(brew --prefix)/Frameworks"

    # NOTE: Python from Homebrew will have a hardcoded sysroot pointing to Xcode.app directory wchich might not exist.
    # This seems to be a robust way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    export CFLAGS
    unset UUID_ROOT
    if [ "$(python3 -c 'import setuptools; print(setuptools.__version__)')" != "60.8.2" ]; then
      echo 'Please install setuptools==60.8.2'
      exit 1
    fi
  ;;
esac

rsync -a --delete "${SOURCEDIR}/" "${BUILDDIR}"

mkdir build
pushd build
cmake "${BUILDDIR}"                                                   \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                       \
      -DCMAKE_INSTALL_PREFIX="${INSTALLROOT}"                           \
      ${CMAKE_FRAMEWORK_PATH+-DCMAKE_FRAMEWORK_PATH=$CMAKE_FRAMEWORK_PATH} \
      -DCMAKE_INSTALL_LIBDIR=lib                                      \
      -DXRDCL_ONLY=ON                                                 \
      -DENABLE_CRYPTO=ON                                              \
      -DENABLE_PERL=OFF                                               \
      -DVOMSXRD_SUBMODULE=OFF                                         \
      ${UUID_ROOT:+-DUUID_LIBRARIES=$UUID_ROOT/lib/libuuid.so}        \
      ${UUID_ROOT:+-DUUID_LIBRARY=$UUID_ROOT/lib/libuuid.so}          \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIRS=$UUID_ROOT/include}            \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIR=$UUID_ROOT/include}             \
      -DENABLE_KRB5=OFF                                               \
      -DENABLE_READLINE=OFF                                           \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                               \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}               \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                            \
      ${XROOTD_PYTHON:+-DENABLE_PYTHON=ON}                            \
      ${XROOTD_PYTHON:+-DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE}        \
      ${XROOTD_PYTHON:+-DXROOTD_PYBUILD_ENV='CC=c++ CFLAGS=\"-std=c++17\"'}       \
      ${XROOTD_PYTHON:+-DPIP_OPTIONS='--force-reinstall --ignore-installed -v'}   \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS:+-j$JOBS} install
popd

if [[ "${XROOTD_PYTHON}" == "True" ]]; then
    pushd "${INSTALLROOT}"

    # there are cases where python bindings are installed as relative to INSTALLROOT
    if [[ -d local/lib64 ]]; then
        [[ -d "local/lib64/python${PYTHON_VER}" ]] && mv -f "local/lib64/python${PYTHON_VER}" lib/
    fi
    if [[ -d local/lib ]]; then
        [[ -d "local/lib/python${PYTHON_VER}" ]] && mv -f "local/lib/python${PYTHON_VER}" lib/
    fi

    pushd lib
    if [ -d "../lib64/python${PYTHON_VER}" ]; then
      ln -s "../lib64/python${PYTHON_VER}" python
    elif [[ -d "python${PYTHON_VER}" ]]; then
      ln -s "python${PYTHON_VER}" python
    fi
    [[ ! -e python ]] && echo "NO PYTHON SYMLINK CREATED in: $(pwd -P)"
    popd  # get back from lib

    popd  # get back from INSTALLROOT

  case $ARCHITECTURE in
      osx*)
        find "$INSTALLROOT/lib/python/" -name "*.so" -exec install_name_tool -add_rpath "${INSTALLROOT}/lib" {} \;
        find "$INSTALLROOT/lib/" -name "*.dylib" -exec install_name_tool -add_rpath "${INSTALLROOT}/lib" {} \;
      ;;
  esac

    # Print found XRootD python bindings
    # just run the the command as this is under "bash -e"
    echo -ne ">>>>>>   Found XRootD python bindings: "
    LD_LIBRARY_PATH="$INSTALLROOT/lib${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH" PYTHONPATH="$INSTALLROOT/lib/python/site-packages${PYTHONPATH:+:}$PYTHONPATH" ${PYTHON_EXECUTABLE} -c 'from XRootD import client as xrd_client;print(f"{xrd_client.__version__}\n{xrd_client.__file__}");'
    echo

fi  # end of PYTHON part

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
if { $XROOTD_PYTHON } {
  prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
}
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
