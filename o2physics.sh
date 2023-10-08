package: O2Physics
version: "%(tag_basename)s"
tag: "daily-20231008-0200"
requires:
  - O2
  - ONNXRuntime
  - fastjet
  - libjalienO2
  - KFParticle
build_requires:
  - "Clang:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
  - alibuild-variant-support
source: https://github.com/AliceO2Group/O2Physics
incremental_recipe: |
  [[ $ALIBUILD_O2PHYSICS_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  case $ALIBUILD_BUILD_VARIANT in
    tutorial) TARGET=Tutorials ;;
    *) TARGET=$ALIBUILD_BUILD_VARIANT ;;
  esac
  # In case a variant is passed, we invoke the build with the variant as target
  alibuild-variant-command ${ALIBUILD_BUILD_VARIANT:-none} cmake --build . -- ${JOBS:+-j$JOBS} $ALIBUILD_BUILD_VARIANT/install
  # No need to continue in case we are using a variant
  alibuild-variant-done ${ALIBUILD_BUILD_VARIANT:-none}
  cmake --build . -- ${JOBS:+-j$JOBS} install
---
#!/bin/sh

if [[ $ALIBUILD_O2PHYSICS_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

# When O2 is built against Gandiva (from Arrow), then we need to use
# -DLLVM_ROOT=$CLANG_ROOT, since O2's CMake calls into Gandiva's
# -CMake, which requires it.
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      -G Ninja                                                    \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                   \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                          \
      ${CLANG_ROOT:+-DLLVM_ROOT="$CLANG_ROOT"}                    \
      ${ONNXRUNTIME_ROOT:+-DONNXRuntime_DIR=$ONNXRUNTIME_ROOT}    \
      ${FASTJET_ROOT:+-Dfjcontrib_ROOT="$FASTJET_ROOT"}           \
      ${LIBJALIENO2_ROOT:+-DlibjalienO2_ROOT=$LIBJALIENO2_ROOT}   \
      ${LIBUV_ROOT:+-DLibUV_ROOT=$LIBUV_ROOT}

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# Modulefile
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
set O2PHYSICS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2PHYSICS_ROOT \$O2PHYSICS_ROOT
prepend-path ROOT_INCLUDE_PATH \$O2PHYSICS_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

# Better naming for some of the the targets
case $ALIBUILD_BUILD_VARIANT in
  tutorial) TARGET=Tutorials ;;
  *) TARGET=$ALIBUILD_BUILD_VARIANT ;;
esac

source $ALIBUILD_VARIANT_SUPPORT
# In case a variant is passed, we invoke the build with the variant as target
alibuild-variant-command ${ALIBUILD_BUILD_VARIANT:-none} cmake --build . -- ${JOBS:+-j$JOBS} $TARGET/install
# No need to continue in case we are using a variant
alibuild-variant-done ${ALIBUILD_BUILD_VARIANT:-none}
cmake --build . -- ${JOBS+-j $JOBS} install
