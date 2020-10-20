package: GLFW
version: "3.3.2"
tag: 3.3.2
source: https://github.com/glfw/glfw.git
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prefer_system: "(?!osx)"
prefer_system_check: |
  printf "#if ! __has_include(<GLFW/glfw3.h>)\n#error \"GLFW not found, checking if we can build it.\"\n#endif\n" | cc -xc++ -std=c++17 - -c -o /dev/null
---

# FIXME: --debug-output somehow needed to get CMake 3.18.2 to work
cmake --debug-output $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}          \
  -DBUILD_SHARED_LIBS=ON                             \
  -DGLFW_BUILD_EXAMPLES=OFF                          \
  -DCMAKE_INSTALL_LIBDIR=lib                         \
  -DGLFW_BUILD_TESTS=OFF                             \
  -DGLFW_BUILD_DOCS=OFF

cmake --build . -- ${JOBS+-j $JOBS} install
# Somehow the id is lib/libglfw.3.3.dylib rather than simply libglfw.3.3.dylib
case $ARCHITECTURE in
  osx*) install_name_tool -id $INSTALLROOT/lib/libglfw.dylib $INSTALLROOT/lib/libglfw.3.*.dylib ;;
esac

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
