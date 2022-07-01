package: BookkeepingApiCpp
version: v0.21.0
tag: "@aliceo2/bookkeeping@0.21.0"
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - cpprestsdk
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Bookkeeping
---
#!/bin/bash -ex

cmake $SOURCEDIR/cpp-api-client                     \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT           \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}   \
      -DCPPREST_ROOT=${CPPRESTSDK_ROOT}             \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
