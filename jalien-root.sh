package: JAliEn-ROOT
version: "%(tag_basename)s"
tag: "0.7.7"
source: https://gitlab.cern.ch/jalien/jalien-root.git
requires:
  - ROOT
  - xjalienfs
  - XRootD
  - libwebsockets
build_requires:
  - json-c
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - zlib
  - Alice-GRID-Utils
append_path:
  ROOT_PLUGIN_PATH: "$JALIEN_ROOT_ROOT/etc/plugins"
  ROOT_INCLUDE_PATH: "$JALIEN_ROOT_ROOT/include"
---
#!/bin/bash -e
SONAME=so
case $ARCHITECTURE in
  osx*)
        SONAME=dylib
	[[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl@3)
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
       ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
       ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DZLIB_ROOT="$ZLIB_ROOT"                           \
      -DXROOTD_ROOT_DIR="$XROOTD_ROOT"                   \
      -DLWS="$LIBWEBSOCKETS_ROOT"
make ${JOBS:+-j $JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
                     ROOT/${ROOT_VERSION}-${ROOT_REVISION}                                                   \\
                     ${XJALIENFS_REVISION:+xjalienfs/$XJALIENFS_VERSION-$XJALIENFS_REVISION}                 \\
                     ${LIBJALIENWS_REVISION:+libjalienws/$LIBJALIENWS_VERSION-$LIBJALIENWS_REVISION}

# Our environment
set JALIEN_ROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$JALIEN_ROOT_ROOT/lib
append-path ROOT_PLUGIN_PATH \$JALIEN_ROOT_ROOT/etc/plugins
prepend-path ROOT_INCLUDE_PATH \$JALIEN_ROOT_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
