package: Ppconsul
version: 0.1.0
tag: e32cf6f80b598760278c018eed546f88292f1735
source: https://github.com/oliora/ppconsul
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - "system-curl:(slc8)"
  - "curl:(?!slc8)"
build_requires:
  - CMake
---
#!/bin/bash -e

case $ARCHITECTURE in
    osx*)
    [[ ! $CURL_ROOT ]] && CURL_ROOT=`brew --prefix curl`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost` ;;
esac

cmake $SOURCEDIR                                 \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DCMAKE_INSTALL_LIBDIR=lib                 \
      -DBUILD_SHARED_LIBS=ON                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}    \
      ${CURL_ROOT:+-DCURL_ROOT=$CURL_ROOT}
cmake --build . -- ${JOBS:+-j$JOBS} install

mkdir -p "$INSTALLROOT/etc/modulefiles"
cat > "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set PPCONSUL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$PPCONSUL_ROOT/lib
EoF
