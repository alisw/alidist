package: InfoLogger
version: "%(tag_basename)s"
tag: v2.1.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - MySQL
build_requires:
  - CMake
  - golang
  - SWIG
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/InfoLogger
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
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
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}              \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root-env > "etc/modulefiles/$PKGNAME"
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
