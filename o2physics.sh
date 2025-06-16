package: O2Physics
version: "%(tag_basename)s"
tag: "daily-20250616-0000"
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
source: https://github.com/AliceO2Group/O2Physics
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

# When O2 is built against Gandiva (from Arrow), then we need to use
# -DLLVM_ROOT=$CLANG_ROOT, since O2's CMake calls into Gandiva's
# -CMake, which requires it.
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"                    \
      -G Ninja                                                              \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"}           \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                             \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                    \
      ${CLANG_ROOT:+-DLLVM_ROOT="$CLANG_ROOT"}                              \
      ${ONNXRUNTIME_ROOT:+-DONNXRuntime_DIR=$ONNXRUNTIME_ROOT}              \
      ${FASTJET_ROOT:+-Dfjcontrib_ROOT="$FASTJET_ROOT"}                     \
      ${LIBJALIENO2_ROOT:+-DlibjalienO2_ROOT=$LIBJALIENO2_ROOT}             \
      ${CLANG_REVISION:+-DCLANG_EXECUTABLE="$CLANG_ROOT/bin-safe/clang"}    \
      ${CLANG_REVISION:+-DLLVM_LINK_EXECUTABLE="$CLANG_ROOT/bin/llvm-link"} \
      ${LIBUV_ROOT:+-DLibUV_ROOT=$LIBUV_ROOT}                               \
      ${ALIBUILD_O2PHYSICS_TESTS:+-DO2PHYSICS_WARNINGS_AS_ERRORS=ON}
cmake --build . -- ${JOBS+-j $JOBS} install

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="$(readlink $SOURCEDIR || echo $SOURCEDIR)"
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
