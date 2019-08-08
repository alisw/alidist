package: QualityControl
version: "%(tag_basename)s"
tag: v0.16.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - libInfoLogger
  - FairRoot
  - Monitoring
  - Configuration
  - O2
  - arrow
build_requires:
  - CMake
  - CodingGuidelines
source: https://github.com/AliceO2Group/QualityControl
prepend_path:
  ROOT_INCLUDE_PATH: "$QUALITYCONTROL_ROOT/include"
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
  osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

# For the PR checkers (which sets ALIBUILD_O2_TESTS),
# we impose -Werror as a compiler flag
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      -DBOOST_ROOT=$BOOST_ROOT                                \
      -DCommon_ROOT=$COMMON_O2_ROOT                           \
      -DConfiguration_ROOT=$CONFIGURATION_ROOT                \
      ${LIBINFOLOGGER_VERSION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT}                       \
      -DO2_ROOT=$O2_ROOT                                      \
      -DFAIRROOTPATH=$FAIRROOT_ROOT                           \
      -DFairRoot_DIR=$FAIRROOT_ROOT                           \
      -DMS_GSL_INCLUDE_DIR=$MS_GSL_ROOT/include               \
      -DARROW_HOME=$ARROW_ROOT                                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                 \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Tests (but not the ones with label "manual" and only if ALIBUILD_O2_TESTS is set)
if [[ $ALIBUILD_O2_TESTS ]]; then
  echo "Run the tests"
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALLROOT/lib
  ctest --output-on-failure -LE manual ;# ${JOBS+-j $JOBS}
fi

# Modulefile
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
module load BASE/1.0                                                                               \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}                                 \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            Monitoring/$MONITORING_VERSION-$MONITORING_REVISION                                    \\
            Configuration/$CONFIGURATION_VERSION-$CONFIGURATION_REVISION                           \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION                                       \\
            ${LIBINFOLOGGER_VERSION:+libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION} \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION                                          \\
            O2/$O2_VERSION-$O2_REVISION                                                            \\
            ${ARROW_VERSION:+arrow/$ARROW_VERSION-$ARROW_REVISION}

# Our environment
setenv QUALITYCONTROL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(QUALITYCONTROL_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib
prepend-path LD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib64
prepend-path ROOT_INCLUDE_PATH \$::env(QUALITYCONTROL_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib" && echo "prepend-path DYLD_LIBRARY_PATH \$::env(QUALITYCONTROL_ROOT)/lib64")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
