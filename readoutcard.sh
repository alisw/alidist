package: ReadoutCard
version: "%(tag_basename)s"
tag: v0.45.5
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - Configuration
  - Monitoring
  - libInfoLogger
  - "PDA:(?!osx|.*aarch64)"
  - "Python"
build_requires:
  - alibuild-recipe-tools
  - CMake
prepend_path:
  PYTHONPATH: $READOUTCARD_ROOT/lib
source: https://github.com/AliceO2Group/ReadoutCard
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

cmake $SOURCEDIR                                                      \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                             \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                      \
      ${COMMON_O2_REVISION:+-DCommon_ROOT=$COMMON_O2_ROOT}             \
      ${CONFIGURATION_REVISION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT} \
      ${MONITORING_REVISION:+-DMonitoring_ROOT=$MONITORING_ROOT} \
      ${LIBINFOLOGGER_REVISION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT} \
      ${PDA_REVISION:+-DPDA_ROOT=$PDA_ROOT}                            \
      ${PYTHON_REVISION:+-DPython3_ROOT_DIR="$PYTHON_ROOT"}            \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                               \
      -DBUILD_SHARED_LIBS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path PYTHONPATH \$PKG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

# External RPM dependencies
cat > $INSTALLROOT/.rpm-extra-deps <<EoF
pda-kadapter-dkms >= 2.0.0
EoF
