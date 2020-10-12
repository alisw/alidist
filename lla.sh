package: LLA
version: "%(tag_basename)s"
tag: v0.1.0
requires:
  - boost
  - Common-O2
  - "GCC-Toolchain:(?!osx)"
  - libInfoLogger
  - ReadoutCard
  - "Python:slc.*"
build_requires:
  - CMake
prepend_path:
  PYTHONPATH: $LLA_ROOT/lib
source: https://github.com/AliceO2Group/LLA
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

# Enforce no warning code in the PR checker
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                                       \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                              \
      ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                         \
      ${COMMON_O2_REVISION:+-DCommon_ROOT=$COMMON_O2_ROOT}             \
      ${LIBINFOLOGGER_REVISION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT} \
      ${READOUTCARD_REVISION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT}    \
      ${PYTHON_REVISION:+-DPython3_ROOT_DIR="$PYTHON_ROOT"}            \
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
module load BASE/1.0                                                                                \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}           \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION                                        \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION                            \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION                                  \\
            ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}

# Our environment
set LLA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LLA_ROOT \$LLA_ROOT
prepend-path PATH \$LLA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LLA_ROOT/lib
prepend-path PYTHONPATH \$LLA_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
