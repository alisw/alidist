package: XRootD
version: "%(tag_basename)s"
tag: v3.3.6-alice1
source: https://github.com/alisw/xrootd.git
build_requires:
 - CMake
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - ApMon-CPP
 - libxml2
 - MonALISA-gSOAP-client
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
                   -DENABLE_PERL=TRUE                                 \
                   -DENABLE_KRB5=FALSE                                \
                   -DENABLE_READLINE=FALSE                            \
                   -DCMAKE_BUILD_TYPE=RelWithDebInfo                  \
                   ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}  \
                   -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"      \
                   -DZLIB_ROOT=$ZLIB_ROOT
make ${JOBS:+-j$JOBS}
make install
ln -sf lib $INSTALLROOT/lib64
