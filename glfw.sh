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
  printf "#include <GLFW/glfw3.h>" | cc -xc - -c -o /dev/null
  if [ $? -ne 0 ]; then printf "GLFW not found.\n * On RHEL-compatible systems you probably need: GLFW3-devel\n * On Ubuntu-compatible systems you probably need: libglfw3-dev\n"; exit 1; fi
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
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
