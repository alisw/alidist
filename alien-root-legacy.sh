package: AliEn-ROOT-Legacy
version: "%(tag_basename)s"
tag: "0.1.3"
source: https://gitlab.cern.ch/jalien/alien-root-legacy.git
requires:
  - ROOT
  - XRootD
  - xalienfs
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - Alice-GRID-Utils
append_path:
  ROOT_PLUGIN_PATH: "$ALIEN_ROOT_LEGACY_ROOT/etc/plugins"
prepend_path:
  ROOT_INCLUDE_PATH: "$ALIEN_ROOT_LEGACY_ROOT/include"
---
#!/bin/bash -e

SONAME=so
if [[ $ARCHITECTURE == osx* ]]; then
  SONAME=dylib
  : "${OPENSSL_ROOT:=$(brew --prefix openssl@3)}"
fi

# Determine whether we are building for ROOT 5 or ROOT 6+
[[ -x "$ROOTSYS/bin/rootcling" ]] && ROOT_MAJOR="v6-00-00" || ROOT_MAJOR="v5-00-00"

rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
rsync -a $ALICE_GRID_UTILS_ROOT/include/ $BUILDDIR/inc

cmake $BUILDDIR                                          \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"              \
      -DROOTSYS="$ROOTSYS"                               \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
       ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include} \
       ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
      -DALIEN_DIR="$XALIENFS_ROOT"                       \
      -DROOT_VERSION="$ROOT_MAJOR"

cmake --build . --target install ${JOBS:+-- -j$JOBS}

if [[ $ARCHITECTURE == osx* ]]; then
  # Due to some ROOT quirks, we create .so symlinks pointing to the real .dylib libs on macOS
  for SYMLIB in "$INSTALLROOT/lib/libAliEnROOTLegacy.so" "$INSTALLROOT/lib/libXrdxAlienFs.so"; do
    [[ ! -e "$SYMLIB" ]] || continue
    SYMDEST=${SYMLIB%.*}
    SYMDEST=${SYMDEST##*/}.dylib
    ln -nfs "$SYMDEST" "$SYMLIB"
  done
fi

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
                     XRootD/${XROOTD_VERSION}-${XROOTD_REVISION}                                             \\
                     xalienfs/${XALIENFS_VERSION}-${XALIENFS_REVISION}

# Our environment
set ALIEN_ROOT_LEGACY_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$ALIEN_ROOT_LEGACY_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ALIEN_ROOT_LEGACY_ROOT/lib
append-path ROOT_PLUGIN_PATH \$ALIEN_ROOT_LEGACY_ROOT/etc/plugins
prepend-path ROOT_INCLUDE_PATH \$ALIEN_ROOT_LEGACY_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
