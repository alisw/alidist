package: Configuration
version: "%(tag_basename)s"
tag:  v2.1.0
requires:
  - curl
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
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT}                 \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include} \
      -DPpconsul_DIR=$PPCONSUL_ROOT

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
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${PPCONSUL_VERSION:+Ppconsul/$PPCONSUL_VERSION-$PPCONSUL_REVISION}

# Our environment
setenv CONFIGURATION_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CONFIGURATION_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(CONFIGURATION_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
