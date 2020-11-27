package: Configuration
version: "%(tag_basename)s"
tag:  v2.5.0
requires:
  - "curl:(?!slc8)"
  - "system-curl:slc8.*"
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Ppconsul
build_requires:
  - CMake
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

mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PPCONSUL_REVISION:+Ppconsul/$PPCONSUL_VERSION-$PPCONSUL_REVISION}

# Our environment
set CONFIGURATION_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv CONFIGURATION_ROOT \$CONFIGURATION_ROOT
prepend-path PATH \$CONFIGURATION_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CONFIGURATION_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
