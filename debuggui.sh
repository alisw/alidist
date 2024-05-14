package: DebugGUI
version: "v0.8.0"
tag: "v0.8.0"
requires:
  - "GCC-Toolchain:(?!osx)"
  - GLFW
  - FreeType
  - libuv
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
source: https://github.com/AliceO2Group/DebugGUI
incremental_recipe: |
  cmake $SOURCEDIR                          \
        -DCMAKE_GENERATOR=Ninja             \
        -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
  cmake --build . -- ${JOBS+-j $JOBS} install

  #ModuleFile
  mkdir -p etc/modulefiles
  alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---

case $ARCHITECTURE in
    osx*)
      [[ ! $GLFW_ROOT ]] && GLFW_ROOT=`brew --prefix glfw`
      [[ ! $LIBUV_ROOT ]] && LIBUV_ROOT=`brew --prefix libuv`
      [[ ! $FREETYPE_ROOT ]] && FREETYPE_ROOT=`brew --prefix freetype`
      EXTRA_LIBS="-framework CoreFoundation -framework AppKit"
      DEFINES="-DNO_PARALLEL_SORT"
    ;;
    *) 
      DEFINES="-DIMGUI_IMPL_OPENGL_LOADER_GL3W -DTRACY_NO_FILESELECTOR -DNO_PARALLEL_SORT"
      EXTRA_LIBS="-lGL"
      ! ld -ltbb -o /dev/null 2>/dev/null || EXTRA_LIBS="${EXTRA_LIBS} -ltbb"
      [[ ! $FREETYPE_ROOT ]] && FREETYPE_ROOT="/usr"       
    ;;
esac

cmake $SOURCEDIR                          \
      -DCMAKE_GENERATOR=Ninja             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
cmake --build . -- ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
