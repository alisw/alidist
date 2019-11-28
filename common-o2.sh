package: Common-O2
version: "%(tag_basename)s"
tag: v1.4.6
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Common
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) 
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    ;;
esac

cmake $SOURCEDIR 				\
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT 	\
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT} 	\
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
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
module load BASE/1.0 ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
setenv COMMON_O2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(COMMON_O2_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(COMMON_O2_ROOT)/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
