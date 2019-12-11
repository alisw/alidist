package: cpprestsdk
version: "%(commit_hash)s"
tag: master
source: https://github.com/Microsoft/cpprestsdk
requires:
- boost
- OpenSSL:(?!osx)
build_requires:
- CMake
---
#!/bin/sh

case $ARCHITECTURE in
  osx*) 
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl)
  ;;
esac

cmake "$SOURCEDIR/Release"                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT               \
      -DBUILD_TESTS=OFF                                 \
      -DBUILD_SAMPLES=OFF                               \
      -DCMAKE_BUILD_TYPE=Debug                          \
      -DCMAKE_CXX_FLAGS=-Wno-error=conversion           \
      -DCPPREST_EXCLUDE_WEBSOCKETS=ON                   \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}        \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}

make ${JOBS:+-j $JOBS}
make install

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
module load BASE/1.0                                                          \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}
# Our environment
set CPPRESTSDK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(CPPRESTSDK_ROOT)/lib64
EoF
