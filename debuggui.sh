package: DebugGUI
version: "v0.1.0-%(short_hash)s"
tag: 34bc77ae9c3ba58a1b6dc684e80fc9187782fd2b
requires:
  - "GCC-Toolchain:(?!osx)"
  - GLFW
  - libuv
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/DebugGUI
---
case $ARCHITECTURE in
    osx*)
      [[ ! $GLFW_ROOT ]] && GLFW_ROOT=`brew --prefix glfw`
      [[ ! $LIBUV_ROOT ]] && LIBUV_ROOT=`brew --prefix libuv`
    ;;
esac

# Use ninja if in devel mode, ninja is found and DISABLE_NINJA is not 1
if [[ ! $CMAKE_GENERATOR && $DISABLE_NINJA != 1 && $DEVEL_SOURCES != $SOURCEDIR ]]; then
  NINJA_BIN=ninja-build
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=ninja
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=
  [[ $NINJA_BIN ]] && CMAKE_GENERATOR=Ninja || true
  unset NINJA_BIN
fi

cmake $SOURCEDIR                          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set DEBUGGUI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$DEBUGGUI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$DEBUGGUI_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
