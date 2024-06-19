package: XRootD
version: "%(tag_basename)s"
tag: "v5.6.6"
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
  - UUID
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: "${XROOTD_ROOT}/lib/python/site-packages"
env:
  XRD_CONNECTIONWINDOW: "3"
  XRD_CONNECTIONRETRY: "1"
  XRD_TIMEOUTRESOLUTION: "1"
  XRD_REQUESTTIMEOUT: "150"
---
#!/bin/bash -e

XROOTD_PYTHON=""
[[ -e ${SOURCEDIR}/bindings ]] && XROOTD_PYTHON=True;
PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )

# Report versions of pip and setuptools
echo "###################
pip version:
$(python3 -m pip -V)
setuptools version:
$(python3 -m pip show setuptools | grep 'Version\|Location')
###################"

COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++
SONAME=so
libuuid_soname=$SONAME

case $ARCHITECTURE in
  osx_*)
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@3)
    # Python from Homebrew will have a hardcoded sysroot pointing to the
    # Xcode.app directory, which might not exist. This seems to be a robust
    # way to discover a working SDK path and present it to Python setuptools.
    # This fix is needed only on MacOS when building XRootD Python bindings.
    export CFLAGS="${CFLAGS} -isysroot $(xcrun --show-sdk-path)"
    COMPILER_CC=clang
    COMPILER_CXX=clang++
    COMPILER_LD=clang
    SONAME=dylib
    libuuid_soname=a   # on Mac, no .dylib is produced
    ;;
esac

case $ARCHITECTURE in
  osx_x86-64) export ARCHFLAGS="-arch x86_64" ;;
  osx_arm64) CMAKE_FRAMEWORK_PATH=$(brew --prefix)/Frameworks ;;
esac

rsync -a --delete ${SOURCEDIR}/ ${BUILDDIR}

mkdir build
pushd build
cmake "${BUILDDIR}"                                                   \
      --log-level DEBUG                                               \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                       \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                              \
      -DCMAKE_C_COMPILER=$COMPILER_CC                                 \
      -DCMAKE_LINKER=$COMPILER_LD                                     \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}                           \
      ${CMAKE_FRAMEWORK_PATH+-DCMAKE_FRAMEWORK_PATH=$CMAKE_FRAMEWORK_PATH} \
      -DCMAKE_INSTALL_LIBDIR=lib                                      \
      -DXRDCL_ONLY=ON                                                 \
      ${UUID_ROOT:+-DUUID_LIBRARY="$UUID_ROOT/lib/libuuid.$libuuid_soname"} \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIR="$UUID_ROOT/include"}           \
      -DENABLE_KRB5=OFF                                               \
      -DENABLE_FUSE=OFF                                               \
      -DENABLE_VOMS=OFF                                               \
      -DENABLE_XRDCLHTTP=OFF                                          \
      -DENABLE_READLINE=OFF                                           \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                               \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}               \
      ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include}   \
      ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                            \
      ${XROOTD_PYTHON:+-DENABLE_PYTHON=ON}                            \
      ${XROOTD_PYTHON:+-DPython_EXECUTABLE=$PYTHON_EXECUTABLE}        \
      ${XROOTD_PYTHON:+-DPIP_OPTIONS='--force-reinstall --ignore-installed --verbose'}   \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS:+-j$JOBS} install
popd

if [[ x"$XROOTD_PYTHON" == x"True" ]]; then
    pushd ${INSTALLROOT}

    # there are cases where python bindings are installed as relative to INSTALLROOT
    if [[ -d local/lib64 ]]; then
        [[ -d local/lib64/python${PYTHON_VER} ]] && mv -f local/lib64/python${PYTHON_VER} lib/
    fi
    if [[ -d local/lib ]]; then
        [[ -d local/lib/python${PYTHON_VER} ]] && mv -f local/lib/python${PYTHON_VER} lib/
    fi

    pushd lib
    if [ -d ../lib64/python${PYTHON_VER} ]; then
      ln -s ../lib64/python${PYTHON_VER} python
    elif [[ -d python${PYTHON_VER} ]]; then
      ln -s python${PYTHON_VER} python
    fi
    [[ ! -e python ]] && echo "NO PYTHON SYMLINK CREATED in: $(pwd -P)"
    popd  # get back from lib

    popd  # get back from INSTALLROOT

  case $ARCHITECTURE in
      osx*)
        find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
        find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
      ;;
  esac

    # Print found XRootD python bindings
    # just run the the command as this is under "bash -e"
    echo -ne ">>>>>>   Found XRootD python bindings: "
    LD_LIBRARY_PATH="$INSTALLROOT/lib${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH" PYTHONPATH="$INSTALLROOT/lib/python/site-packages${PYTHONPATH:+:}$PYTHONPATH" ${PYTHON_EXECUTABLE} -c 'from XRootD import client as xrd_client;print(f"{xrd_client.__version__}\n{xrd_client.__file__}");'
    echo

fi  # end of PYTHON part

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin --lib --cmake > "$MODULEFILE"

case $ARCHITECTURE in
  slc[78]*) OPTIONAL_ENV= ;;
  *) OPTIONAL_ENV="" ;;
esac

cat >> "$MODULEFILE" <<EoF
setenv ${OPTIONAL_ENV}XRD_CONNECTIONWINDOW 3
setenv ${OPTIONAL_ENV}XRD_CONNECTIONRETRY 1
setenv ${OPTIONAL_ENV}XRD_TIMEOUTRESOLUTION 1
setenv ${OPTIONAL_ENV}XRD_REQUESTTIMEOUT 150

if { $XROOTD_PYTHON } {
  prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
  # This is probably redundant, but should not harm.
  module load ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
              ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
}
EoF
