package: XRootD
version: "%(tag_basename)s"
tag: v3.3.6-alice2
source: https://github.com/alisw/xrootd.git
build_requires:
 - CMake
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - ApMon-CPP
 - libxml2
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*)
    [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl)
  ;;
esac
cmake "$SOURCEDIR"                                      \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT               \
      -DCMAKE_INSTALL_LIBDIR=lib                        \
      -DENABLE_CRYPTO=ON                                \
      -DENABLE_PERL=OFF                                 \
      -DENABLE_PYTHON=OFF                               \
      -DENABLE_KRB5=OFF                                 \
      -DENABLE_READLINE=OFF                             \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo                 \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"     \
      -DZLIB_ROOT=$ZLIB_ROOT
cmake --build . -- ${JOBS:+-j$JOBS} install

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
module load BASE/1.0 \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION} \\
            ${LIBXML2_REVISION:+libxml2/$LIBXML2_VERSION-$LIBXML2_REVISION}
# Our environment
set XROOTD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$XROOTD_ROOT/bin
prepend-path LD_LIBRARY_PATH \$XROOTD_ROOT/lib
EoF
