package: O2
version: "1.0.0"
tag: "O2-1.0.0"
requires:
  - arrow
  - FairRoot
  - DDS
  - Vc
  - hijing
  - HepMC3
  - libInfoLogger
  - Common-O2
  - Configuration
  - Monitoring
  - ms_gsl
  - FairMQ
  - curl
  - MCStepLogger
  - AEGIS
  - fmt
build_requires:
  - RapidJSON
  - googlebenchmark
  - cub
source: https://github.com/AliceO2Group/AliceO2
prepend_path:
  ROOT_INCLUDE_PATH: "$O2_ROOT/include:$O2_ROOT/include/GPU"
incremental_recipe: |
  unset DYLD_LIBRARY_PATH
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  # install the compilation database so that we can post-check the code
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

  DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
  # This really means we are in development mode. We need to make sure we
  # use the real path for sources in this case. We also copy the
  # compile_commands.json file so that IDEs can make use of it directly, this
  # is a departure from our "no changes in sourcecode" policy, but for a good reason
  # and in any case the file is in gitignore.
  if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
    perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
    ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
  fi
  if [[ $ALIBUILD_O2_TESTS ]]; then
    export O2_ROOT=$INSTALLROOT
    export VMCWORKDIR=$O2_ROOT/share
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$O2_ROOT/lib
    if [[ ! $BOOST_VERSION && $ARCHITECTURE == osx* ]]; then
      export ROOT_INCLUDE_PATH=$(brew --prefix boost)/include:$ROOT_INCLUDE_PATH
    fi
    export ROOT_INCLUDE_PATH=$INSTALLROOT/include:$INSTALLROOT/include/GPU:$ROOT_INCLUDE_PATH
    # Clean up old coverage data and tests logs
    find . -name "*.gcov" -o -name "*.gcda" -delete
    # cleanup ROOT files created by tests in build area
    find $PWD -name "*.root" -delete
    rm -rf test_logs
    TESTERR=
    ctest -E test_Framework --output-on-failure ${JOBS+-j $JOBS} || TESTERR=$?
    ctest -R test_Framework --output-on-failure || TESTERR=$?
    # Display additional logs for tests that timed out in a non-fatal way
    set +x
    for LOG in test_logs/*.nonfatal; do
      [[ -e $LOG ]] || continue
      printf "\n\n\n\n\n\n"
      cat "$LOG"
      printf "\n\n\n\n\n\n"
    done
    set -x
    [[ ! $TESTERR ]] || exit 1
  fi
  # Create code coverage information to be uploaded
  # by the calling driver to codecov.io or similar service
  if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
    rm -rf coverage.info
    lcov --base-directory $SOURCEDIR --directory . --capture --output-file coverage.info
    lcov --remove coverage.info '*/usr/*' --output-file coverage.info
    lcov --remove coverage.info '*/boost/*' --output-file coverage.info
    lcov --remove coverage.info '*/ROOT/*' --output-file coverage.info
    lcov --remove coverage.info '*/FairRoot/*' --output-file coverage.info
    lcov --remove coverage.info '*/G__*Dict*' --output-file coverage.info
    perl -p -i -e "s|$SOURCEDIR||g" coverage.info # Remove the absolute path for sources
    perl -p -i -e "s|$BUILDDIR||g" coverage.info # Remove the absolute path for generated files
    perl -p -i -e "s|^[0-9]+/||g" coverage.info # Remove PR location path
    lcov --list coverage.info
  fi
valid_defaults:
  - o2
  - o2-dataflow
  - o2-dev-fairroot
  - alo
  - o2-prod
---
#!/bin/sh
export ROOTSYS=$ROOT_ROOT

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $GLFW_ROOT ]] && GLFW_ROOT=`brew --prefix glfw`
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac

# For the PR checkers (which sets ALIBUILD_O2_TESTS)
# we impose -Werror as a compiler flag
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

# Use ninja if in devel mode, ninja is found and DISABLE_NINJA is not 1
if [[ ! $CMAKE_GENERATOR && $DISABLE_NINJA != 1 && $DEVEL_SOURCES != $SOURCEDIR ]]; then
  NINJA_BIN=ninja-build
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=ninja
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=
  [[ $NINJA_BIN ]] && CMAKE_GENERATOR=Ninja || true
  unset NINJA_BIN
fi

unset DYLD_LIBRARY_PATH
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                        \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                             \
      -DCMAKE_MODULE_PATH="$SOURCEDIR/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules_old"  \
      -DFairRoot_DIR=$FAIRROOT_ROOT                                                         \
      -DALICEO2_MODULAR_BUILD=ON                                                            \
      -DROOTSYS=$ROOTSYS                                                                    \
      ${PYTHIA6_ROOT:+-DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib}                              \
      ${GEANT3_ROOT:+-DGeant3_DIR=$GEANT3_ROOT}                                             \
      ${GEANT4_ROOT:+-DGeant4_DIR=$GEANT4_ROOT}                                             \
      ${VGM_ROOT:+-DVGM_DIR=$VGM_ROOT}                                                      \
      ${GEANT4_VMC_ROOT:+-DGEANT4_VMC_DIR=$GEANT4_VMC_ROOT}                                 \
      -DFAIRROOTPATH=$FAIRROOT_ROOT                                                         \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                               \
      ${DDS_ROOT:+-DDDS_PATH=$DDS_ROOT}                                                     \
      -DZMQ_DIR=$ZEROMQ_ROOT                                                                \
      -DZMQ_INCLUDE_DIR=$ZEROMQ_ROOT/include                                                \
      ${ALIROOT_VERSION:+-DALIROOT=$ALIROOT_ROOT}                                           \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.$SONAME}           \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.$SONAME} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.$SONAME}      \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                       \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}              \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                      \
      ${PYTHIA_ROOT:+-DPYTHIA8_INCLUDE_DIR=$PYTHIA_ROOT/include}                            \
      ${HEPMC3_ROOT:+-DHEPMC3_DIR=$HEPMC3_ROOT}                                             \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                             \
      ${ALIBUILD_O2_TESTS:+-DENABLE_CASSERT=ON}                                             \
      -DMS_GSL_INCLUDE_DIR=$MS_GSL_ROOT/include                                             \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                    \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
      ${MONITORING_VERSION:+-DMonitoring_ROOT=$MONITORING_ROOT}                             \
      ${CONFIGURATION_VERSION:+-DConfiguration_ROOT=$CONFIGURATION_ROOT}                    \
      ${LIBINFOLOGGER_VERSION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT}                       \
      ${COMMON_O2_VERSION:+-DCommon_O2_ROOT=$COMMON_O2_ROOT}                                \
      -DRAPIDJSON_INCLUDEDIR=${RAPIDJSON_ROOT}/include                                      \
      ${ARROW_ROOT:+-DARROW_HOME=$ARROW_ROOT}                                               \
      -Dbenchmark_DIR=${GOOGLEBENCHMARK_ROOT}/lib/cmake/benchmark                           \
      ${GLFW_ROOT:+-DGLFW_LOCATION=$GLFW_ROOT}                                              \
      ${FMT_ROOT:+-DFMT_DIR=${FMT_ROOT}}                                                    \
      ${CUB_ROOT:+-DCUB_ROOT=$CUB_ROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

# install the compilation database so that we can post-check the code
cp compile_commands.json ${INSTALLROOT}

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
# This really means we are in development mode. We need to make sure we
# use the real path for sources in this case. We also copy the
# compile_commands.json file so that IDEs can make use of it directly, this
# is a departure from our "no changes in sourcecode" policy, but for a good reason
# and in any case the file is in gitignore.
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
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
module load BASE/1.0 FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION ${DDS_VERSION:+DDS/$DDS_VERSION-$DDS_REVISION} ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${VC_VERSION:+Vc/$VC_VERSION-$VC_REVISION} ${HEPMC3_VERSION:+HepMC3/$HEPMC3_VERSION-$HEPMC3_REVISION} ${MONITORING_VERSION:+Monitoring/$MONITORING_VERSION-$MONITORING_REVISION} ${CONFIGURATION_VERSION:+Configuration/$CONFIGURATION_VERSION-$CONFIGURATION_REVISION} ${LIBINFOLOGGER_VERSION:+libInfoLogger/$LIBINFOLOGGER_VERSION-$LIBINFOLOGGER_REVISION} ${COMMON_O2_VERSION:+Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION} ms_gsl/$MS_GSL_VERSION-$MS_GSL_REVISION ${ARROW_VERSION:+arrow/$ARROW_VERSION-$ARROW_REVISION} ${AEGIS_VERSION:+AEGIS/$AEGIS_VERSION-$AEGIS_REVISION}
# Our environment
setenv O2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VMCWORKDIR \$::env(O2_ROOT)/share
prepend-path PATH \$::env(O2_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(O2_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx && ! $BOOST_VERSION ]] && echo "prepend-path ROOT_INCLUDE_PATH $BOOST_ROOT/include")
prepend-path ROOT_INCLUDE_PATH \$::env(O2_ROOT)/include/GPU
prepend-path ROOT_INCLUDE_PATH \$::env(O2_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(O2_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

if [[ $ALIBUILD_O2_TESTS ]]; then
  export O2_ROOT=$INSTALLROOT
  export VMCWORKDIR=$O2_ROOT/share
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$O2_ROOT/lib
  if [[ ! $BOOST_VERSION && $ARCHITECTURE == osx* ]]; then
    export ROOT_INCLUDE_PATH=$(brew --prefix boost)/include:$ROOT_INCLUDE_PATH
  fi
  export ROOT_INCLUDE_PATH=$INSTALLROOT/include:$INSTALLROOT/include/GPU:$ROOT_INCLUDE_PATH
  # Clean up old coverage data and tests logs
  find . -name "*.gcov" -o -name "*.gcda" -delete
  rm -rf test_logs
  # cleanup ROOT files created by tests in build area
  find $PWD -name "*.root" -delete
  TESTERR=
  ctest -E test_Framework --output-on-failure ${JOBS+-j $JOBS} || TESTERR=$?
  ctest -R test_Framework --output-on-failure || TESTERR=$?
  # Display additional logs for tests that timed out in a non-fatal way
  set +x
  for LOG in test_logs/*.nonfatal; do
    [[ -e $LOG ]] || continue
    printf "\n\n\n\n\n\n"
    cat "$LOG"
    printf "\n\n\n\n\n\n"
  done
  set -x
  [[ ! $TESTERR ]] || exit 1
fi

# Create code coverage information to be uploaded
# by the calling driver to codecov.io or similar service
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  rm -rf coverage.info
  lcov --base-directory $SOURCEDIR --directory . --capture --output-file coverage.info
  lcov --remove coverage.info '*/usr/*' --output-file coverage.info
  lcov --remove coverage.info '*/boost/*' --output-file coverage.info
  lcov --remove coverage.info '*/ROOT/*' --output-file coverage.info
  lcov --remove coverage.info '*/FairRoot/*' --output-file coverage.info
  lcov --remove coverage.info '*/G__*Dict*' --output-file coverage.info
  perl -p -i -e "s|$SOURCEDIR||g" coverage.info # Remove the absolute path for sources
  perl -p -i -e "s|$BUILDDIR||g" coverage.info # Remove the absolute path for generated files
  perl -p -i -e "s|^[0-9]+/||g" coverage.info # Remove PR location path
  lcov --list coverage.info
fi
