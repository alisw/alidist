package: GLFW
version: "3.3-%(short_hash)s"
tag: 090b16bfae282606472f876d6b2fd23f
source: https://github.com/glfw/glfw.git
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!osx)"
prefer_system_check: |
  printf "#if ! __has_include(<GLFW/glfw3.h>)\n#error \"GLFW not found, checking if we can build it.\"\n#endif\n" | cc -xc++ -std=c++17 - -c -o /dev/null
---
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
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
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat >"$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
set GLFW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$GLFW_ROOT/lib
EoF
