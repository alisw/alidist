package: Configuration
version: "%(tag_basename)s"
tag:  v1.3.0
requires:
  - curl
  - boost
  - "GCC-Toolchain:(?!osx)"
  - RapidJSON
  - "Ppconsul:(?!osx)"
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Configuration
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

LIBEXT=so
case $ARCHITECTURE in
    osx*)
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
      LIBEXT=dylib
    ;;
esac

cmake $SOURCEDIR                                                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                            \
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT}                                             \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include}                             \
      -DRAPIDJSON_INCLUDEDIR=${RAPIDJSON_ROOT}/include                                   \
      -DPPCONSUL_INCLUDE_DIRS=${PPCONSUL_ROOT}/include                                   \
      -DPPCONSUL_LIBRARY_DIRS=${PPCONSUL_ROOT}/lib                                       \

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
setenv Configuration_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(Configuration_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(Configuration_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
