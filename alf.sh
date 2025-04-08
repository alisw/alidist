package: ALF
version: "%(tag_basename)s"
tag: v0.19.2
requires:
  - boost
  - Common-O2
  - "dim:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
  - LLA
  - ReadoutCard
  - "DimRpcParallel:(?!osx)"
  - "Python:slc.*"
build_requires:
  - alibuild-recipe-tools
  - CMake
source: https://github.com/AliceO2Group/ALF
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

# Enforce no warning code in the PR checker
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                             \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                      \
      ${COMMON_O2_REVISION:+-DCommon_ROOT=$COMMON_O2_ROOT}             \
      ${DIM_REVISION:+-DDIM_ROOT=$DIM_ROOT}                            \
      ${READOUTCARD_REVISION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT}    \
      ${PYTHON_ROOT:+-DPython3_EXECUTABLE="$(which python3)"}          \
      ${LLA_REVISION:+-DLLA_ROOT=$LLA_ROOT}    \
      ${DIM_RPC_PARALLEL_REVISION:+-DDIM_RPC_PARALLEL_ROOT=$DIM_RPC_PARALLEL_ROOT}    \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path PYTHONPATH \$PKG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
