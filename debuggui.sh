package: DebugGUI
version: "v0.6.8"
tag: "v0.6.8"
requires:
  - "GCC-Toolchain:(?!osx)"
  - GLFW
  - FreeType
  - libuv
build_requires:
  - capstone
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

# build the tracy profiler
rsync -av $SOURCEDIR/tracy/ tracy/
pushd tracy/profiler/build/unix
  make ${JOBS+-j $JOBS}                                                                                                         \
      LIBS="-L$CAPSTONE_ROOT/lib -L$GLFW_ROOT/lib -L$FREETYPE_ROOT/lib -lglfw -lfreetype -lcapstone -lpthread -ldl $EXTRA_LIBS" \
      DEFINES="$DEFINES"                                                                                                        \
      TBB=off                                                                                                                   \
      TRACY_NO_FILESELECTOR=1                                                                                                   \
      INCLUDES="-I$CAPSTONE_ROOT/include/capstone -I$SOURCEDIR/tracy/imgui -I$SOURCEDIR/tracy -I$SOURCEDIR/tracy/profiler/libs/gl3w ${FREETYPE_ROOT:+-I$FREETYPE_ROOT/include/freetype2} -I${GLFW_ROOT:+$GLFW_ROOT/include}"
popd
mkdir -p $INSTALLROOT/{include/tracy,bin}
cp tracy/profiler/build/unix/Tracy-* $INSTALLROOT/bin/tracy-profiler
cp tracy/*.{h,hpp,cpp} $INSTALLROOT/include/tracy
cp -r tracy/{common,client,libbacktrace} $INSTALLROOT/include/tracy/

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
