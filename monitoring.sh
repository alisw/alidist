package: Monitoring
version: "%(tag_basename)s"
tag: v1.9.5
requires:
  - curl
  - boost
  - "GCC-Toolchain:(?!osx)"
  - ApMon-CPP
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Monitoring
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${APMON_CPP_VERSION:+-DAPMON_ROOT=$APMON_CPP_ROOT}         \
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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${APMON_CPP_VERSION:+ApMon-CPP/$APMON_CPP_VERSION-$APMON_CPP_REVISION}  ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
setenv MONITORING_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(MONITORING_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(MONITORING_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MONITORING_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
