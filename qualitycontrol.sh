package: QualityControl
version: "%(tag_basename)s"
tag: v1.13.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Common-O2
  - libInfoLogger
  - Monitoring
  - Configuration
  - O2
  - arrow
  - Control-OCCPlugin
  - Python-modules
build_requires:
  - CMake
  - CodingGuidelines
  - RapidJSON
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/QualityControl
prepend_path:
  ROOT_INCLUDE_PATH: "$QUALITYCONTROL_ROOT/include"
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
  # Tests (but not the ones with label "manual" and only if ALIBUILD_O2_TESTS is set )
  if [[ $ALIBUILD_O2_TESTS ]]; then
    echo "Run the tests"
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALLROOT/lib
    PATH=$PATH:$INSTALLROOT/bin
    ROOT_DYN_PATH=$ROOT_DYN_PATH:$INSTALLROOT/lib ctest --output-on-failure -LE manual ${JOBS+-j $JOBS}
  fi
---
#!/bin/bash -ex

case $ARCHITECTURE in
  osx*) 
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
      [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT_DIR=$(brew --prefix openssl)
      [[ ! $LIBUV_ROOT ]] && LIBUV_ROOT=$(brew --prefix libuv)
      SONAME=dylib
  ;;
  *) 
      SONAME=so
  ;;
esac

# For the PR checkers (which sets ALIBUILD_O2_TESTS),
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

cmake $SOURCEDIR                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}               \
      -DBOOST_ROOT=$BOOST_ROOT                                \
      -DCommon_ROOT=$COMMON_O2_ROOT                           \
      -DConfiguration_ROOT=$CONFIGURATION_ROOT                \
      ${LIBINFOLOGGER_REVISION:+-DInfoLogger_ROOT=$LIBINFOLOGGER_ROOT}                       \
      -DO2_ROOT=$O2_ROOT                                      \
      -DMS_GSL_INCLUDE_DIR=$MS_GSL_ROOT/include               \
      -DARROW_HOME=$ARROW_ROOT                                \
      ${CONTROL_OCCPLUGIN_REVISION:+-DOcc_ROOT=$CONTROL_OCCPLUGIN_ROOT}                      \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                 \
      ${OPENSSL_ROOT_DIR:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR}          \
      ${LIBUV_ROOT:+-DLibUV_INCLUDE_DIR=$LIBUV_ROOT/include}             \
      ${LIBUV_ROOT:+-DLibUV_LIBRARY=$LIBUV_ROOT/lib/libuv.$SONAME}       \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Tests (but not the ones with label "manual" and only if ALIBUILD_O2_TESTS is set)
if [[ $ALIBUILD_O2_TESTS ]]; then
  echo "Run the tests"
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALLROOT/lib
  PATH=$PATH:$INSTALLROOT/bin
  ROOT_DYN_PATH=$ROOT_DYN_PATH:$INSTALLROOT/lib ctest --output-on-failure -LE manual ${JOBS+-j $JOBS}
fi

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
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME

# Our environment
cat >> etc/modulefiles/$PKGNAME <<EoF
setenv QUALITYCONTROL_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

# Create code coverage information to be uploaded
# by the calling driver to codecov.io or similar service
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  rm -rf coverage.info
  lcov --base-directory $SOURCEDIR --directory . --capture --output-file coverage.info
  lcov --remove coverage.info '*/usr/*' --output-file coverage.info
  lcov --remove coverage.info '*/boost/*' --output-file coverage.info
  lcov --remove coverage.info '*/ROOT/*' --output-file coverage.info
  lcov --remove coverage.info '*/G__*Dict*' --output-file coverage.info
  perl -p -i -e "s|$SOURCEDIR||g" coverage.info # Remove the absolute path for sources
  perl -p -i -e "s|$BUILDDIR||g" coverage.info # Remove the absolute path for generated files
  perl -p -i -e "s|^[0-9]+/||g" coverage.info # Remove PR location path
  lcov --list coverage.info
fi

# Add extra RPM dependencies
cat > $INSTALLROOT/.rpm-extra-deps <<EOF
glfw # because the build machine some times happen to have glfw installed. Then it is necessary to have it in the destination
EOF
