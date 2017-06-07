package: Configuration
requires:
  - curl
  - boost
  - "GCC-Toolchain:(?!osx)"
  - protobuf
  - grpc
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Configuration
version:  v1.0.0
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

case $ARCHITECTURE in
  osx*) BOOST_ROOT=$(brew --prefix boost) ;;
esac

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      -DCMAKE_PREFIX_PATH=$PROTOBUF_ROOT                      \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT}                  \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include}

make ${JOBS+-j $JOBS} install

#ModuleFile
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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}  ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION grpc/$GRPC_VERSION-$GRPC_REVISION 
# Our environment
setenv Configuration_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(Configuration_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(Configuration_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
