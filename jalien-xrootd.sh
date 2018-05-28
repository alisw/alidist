package: JAlien-XRootD
version: "%(tag_basename)s"
tag: 4.8.3
build_requires:
 - CMake
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - ApMon-CPP
 - libxml2
 - "GCC-Toolchain:(?!osx)"
---
#! /bin/bash -e

PACKED_NAME="xrootd-$GIT_TAG.tar.gz"

# name of the directory once we unzip
UNPACKED_NAME="xrootd-$GIT_TAG"
URL="http://xrootd.org/download/v$GIT_TAG/$PACKED_NAME"
curl -L -O $URL
tar xfvz $PACKED_NAME

case $ARCHITECTURE in
   osx*)
     [ ! "X$OPENSSL_ROOT" = X ] || OPENSSL_ROOT=`brew --prefix openssl`
   ;;
esac
cmake "$UNPACKED_NAME" -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                \
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
setenv JALIEN_XROOTD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JALIEN_XROOTD_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JALIEN_XROOTD_ROOT)/lib
EoF
