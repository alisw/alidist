package: bookkeeping-api
version: "v0.59.0"
tag: "@aliceo2/bookkeeping@0.59.0"
requires:
  - grpc
  - protobuf
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Bookkeeping
incremental_recipe: |
  cmake --build . -- ${JOBS+-j $JOBS} install
  mkdir -p "$INSTALLROOT/etc/modulefiles"
  rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ -z "$OPENSSL_ROOT" ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl@1.1)
    [[ -z "$GRPC_ROOT" ]] && GRPC_ROOT=$(brew --prefix grpc)
  ;;
esac

cmake $SOURCEDIR/cxx-client                  \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CONFIGURATION_REVISION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${INFOLOGGER_REVISION:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT} \
      -DCMAKE_INSTALL_LIBDIR=lib          \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

VERBOSE=1 cmake --build . -- ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
