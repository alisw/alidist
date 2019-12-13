package: Monitoring
version: "%(tag_basename)s"
tag: v2.6.3
requires:
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

if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${APMON_CPP_REVISION:+-DAPMON_ROOT=$APMON_CPP_ROOT}         \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON 

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

make ${JOBS+-j $JOBS} install

if [[ $ALIBUILD_O2_TESTS ]]; then
  make test
fi

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
module load BASE/1.0 ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${APMON_CPP_REVISION:+ApMon-CPP/$APMON_CPP_VERSION-$APMON_CPP_REVISION}  ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set MONITORING_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MONITORING_ROOT \$MONITORING_ROOT
prepend-path PATH \$MONITORING_ROOT/bin
prepend-path LD_LIBRARY_PATH \$MONITORING_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
