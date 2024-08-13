package: InfoLogger
version: "%(tag_basename)s"
tag: v2.7.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - MySQL
build_requires:
  - CMake
  - golang
  - SWIG
source: https://github.com/AliceO2Group/InfoLogger
incremental_recipe: |
  ninja ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

# Enforce no warning code in the PR checker
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      -G Ninja                                                \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}             \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
ninja ${JOBS+-j $JOBS} install

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
module load BASE/1.0                                                          \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set INFOLOGGER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv INFOLOGGER_ROOT \$INFOLOGGER_ROOT
prepend-path PATH \$INFOLOGGER_ROOT/bin
prepend-path LD_LIBRARY_PATH \$INFOLOGGER_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$INFOLOGGER_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
