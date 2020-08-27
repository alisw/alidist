package: DebugGUI
version: "v0.2.0"
tag: f3d259727ffbe7426031dd99fd4742003eb3e6b5
requires:
  - "GCC-Toolchain:(?!osx)"
  - GLFW
  - FreeType
  - libuv
build_requires:
  - capstone
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/DebugGUI
---

case $ARCHITECTURE in
    osx*)
      [[ ! $GLFW_ROOT ]] && GLFW_ROOT=`brew --prefix glfw`
      [[ ! $LIBUV_ROOT ]] && LIBUV_ROOT=`brew --prefix libuv`
      [[ ! $FREETYPE_ROOT ]] && FREETYPE_ROOT=`brew --prefix freetype`
      EXTRA_LIBS="-framework CoreFoundation -framework AppKit"
    ;;
    *) 
      DEFINES="-DIMGUI_IMPL_OPENGL_LOADER_GL3W -DTRACY_NO_FILESELECTOR"
      EXTRA_LIBS="-lGL"
      ! ld -ltbb -o /dev/null 2>/dev/null || EXTRA_LIBS="${EXTRA_LIBS} -ltbb"
      [[ ! $FREETYPE_ROOT ]] && FREETYPE_ROOT="/usr"       
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

# build the tracy profiler
rsync -av $SOURCEDIR/tracy/ tracy/
pushd tracy/profiler/build/unix
  make                                                                                                                          \
      LIBS="-L$CAPSTONE_ROOT/lib -L$GLFW_ROOT/lib -L$FREETYPE_ROOT/lib -lglfw -lfreetype -lcapstone -lpthread -ldl $EXTRA_LIBS" \
      DEFINES="$DEFINES"                                                                                                        \
      TBB=off                                                                                                                   \
      INCLUDES="-I$CAPSTONE_ROOT/include -I$SOURCEDIR/tracy/imgui -I$SOURCEDIR/tracy -I$SOURCEDIR/tracy/profiler/libs/gl3w ${FREETYPE_ROOT:+-I$FREETYPE_ROOT/include/freetype2} -I${GLFW_ROOT:+$GLFW_ROOT/include}"
popd
mkdir -p $INSTALLROOT/{include/tracy,bin}
cp tracy/profiler/build/unix/Tracy-debug $INSTALLROOT/bin/tracy-profiler
cp tracy/*.{h,hpp,cpp} $INSTALLROOT/include/tracy
cp -r tracy/{common,client,libbacktrace} $INSTALLROOT/include/tracy/

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
