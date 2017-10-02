package: ReadoutCard
version: "%(tag_basename)s"
tag: v0.3.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - InfoLogger
  - "PDA:slc7.*"
  - "dim:(?!osx)"
build_requires:
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
  osx*) BOOST_ROOT=$(brew --prefix boost) ;;
esac

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}                 \
      ${COMMON_O2_VERSION:+-DCommon_ROOT=$COMMON_O2_ROOT}     \
      ${INFOLOGGER_VERSION:+-DInfoLogger_ROOT=$INFOLOGGER_ROOT} \
      ${PDA_VERSION:+-DPDA_ROOT=$PDA_ROOT}                    \
      ${DIM_VERSION:+-DDIM_ROOT=$DIM_ROOT}                    \
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
# Dependencies GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION
module load BASE/1.0                                                          \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION                  \\
            InfoLogger/$INFOLOGGER_VERSION-$INFOLOGGER_REVISION               \\
            PDA/$PDA_VERSION-$PDA_REVISION                                    \\
            dim/$DIM_VERSION-$DIM_REVISION 

# Our environment
setenv READOUTCARD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(READOUTCARD_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(READOUTCARD_ROOT)/lib
prepend-path PYTHONPATH \$::env(READOUTCARD_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(READOUTCARD_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
