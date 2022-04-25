package: Ppconsul
version: "%(tag_basename)s"
tag: v0.2.3
source: https://github.com/oliora/ppconsul
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - curl
build_requires:
  - CMake
  - alibuild-recipe-tools
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

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
