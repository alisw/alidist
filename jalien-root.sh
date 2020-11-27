package: JAliEn-ROOT
version: "%(tag_basename)s"
tag: "0.6.3"
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
append_path:
  ROOT_PLUGIN_PATH: "$JALIEN_ROOT_ROOT/etc/plugins"
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
      -DROOTSYS="$ROOTSYS"                               \
      -DJSONC="$JSON_C_ROOT"                             \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
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
prepend-path PATH \$JALIEN_ROOT_ROOT/bin
prepend-path LD_LIBRARY_PATH \$JALIEN_ROOT_ROOT/lib
append-path ROOT_PLUGIN_PATH \$JALIEN_ROOT_ROOT/etc/plugins
prepend-path ROOT_INCLUDE_PATH \$JALIEN_ROOT_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
