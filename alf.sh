package: ALF
version: "%(tag_basename)s"
tag: v0.10.0
requires:
  - boost
  - Common-O2
  - "dim:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
  - libInfoLogger
  - LLA
  - ReadoutCard
build_requires:
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
      ${LIBINFOLOGGER_REVISION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT} \
      ${READOUTCARD_REVISION:+-DReadoutCard_ROOT=$READOUTCARD_ROOT}    \
      ${LLA_REVISION:+-DLLA_ROOT=$LLA_ROOT}    \
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
module load BASE/1.0                                                          \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}           \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION                  \\
            ${DIM_REVISION:+dim/$DIM_VERSION-$DIM_REVISION}                    \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION      \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION          \\
            LLA/$LLA_VERSION-$LLA_REVISION

# Our environment
set ALF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ALF_ROOT \$ALF_ROOT
prepend-path PATH \$ALF_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ALF_ROOT/lib
prepend-path PYTHONPATH \$ALF_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
