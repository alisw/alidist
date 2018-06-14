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
    [ ! "X$OPENSSL_ROOT" = X ] || OPENSSL_ROOT=`brew --prefix openssl`
  ;;
esac
cmake "$SOURCEDIR" -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                \
                   -DCMAKE_INSTALL_LIBDIR=$INSTALLROOT/lib            \
                   -DENABLE_CRYPTO=TRUE                               \
                   -DENABLE_PERL=FALSE                                \
                   -DENABLE_KRB5=FALSE                                \
                   -DENABLE_READLINE=FALSE                            \
                   -DCMAKE_BUILD_TYPE=RelWithDebInfo                  \
                   ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}  \
                   -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"      \
                   -DZLIB_ROOT=$ZLIB_ROOT
make ${JOBS:+-j$JOBS}
make install
ln -sf lib $INSTALLROOT/lib64

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
module load BASE/1.0
# Our environment
set XROOTD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$XROOTD_ROOT/bin
prepend-path LD_LIBRARY_PATH \$XROOTD_ROOT/lib
EoF
