package: Configuration
version: "%(tag_basename)s"
tag: v2.8.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Ppconsul
  - curl
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Configuration
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

case $ARCHITECTURE in
    osx*)
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    ;;
esac

cmake $SOURCEDIR                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                    \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                \
      -Dppconsul_DIR=${PPCONSUL_ROOT}/cmake

make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
