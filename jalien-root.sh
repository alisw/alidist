package: JAliEn-ROOT
version: "%(tag_basename)s"
tag: "0.6.6"
source: https://gitlab.cern.ch/jalien/jalien-root.git
requires:
  - ROOT
  - xjalienfs
  - XRootD
build_requires:
  - libwebsockets
  - json-c
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - zlib
  - Alice-GRID-Utils
  - alibuild-recipe-tools
append_path:
  ROOT_PLUGIN_PATH: "$JALIEN_ROOT_ROOT/etc/plugins"
  ROOT_INCLUDE_PATH: "$JALIEN_ROOT_ROOT/include"
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*) 
	[[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl)
	[[ ! $LIBWEBSOCKETS_ROOT ]] && LIBWEBSOCKETS_ROOT=$(brew --prefix libwebsockets)
  ;;
esac

rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
rsync -a $ALICE_GRID_UTILS_ROOT/include/ $BUILDDIR/inc

cmake $BUILDDIR                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"              \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=${CXXSTD}}          \
      -DROOTSYS="$ROOTSYS"                               \
      -DJSONC="$JSON_C_ROOT"                             \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
      -DZLIB_ROOT="$ZLIB_ROOT"                           \
      -DXROOTD_ROOT_DIR="$XROOTD_ROOT"                   \
      -DLWS="$LIBWEBSOCKETS_ROOT"
make ${JOBS:+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --extra > "etc/modulefiles/$PKGNAME" <<\EoF
append-path ROOT_PLUGIN_PATH $PKG_ROOT/etc/plugins
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
