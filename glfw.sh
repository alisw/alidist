package: GLFW
version: "3.3"
source: https://github.com/glfw/glfw.git
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
  -DBUILD_SHARED_LIBS=ON \
  -DGLFW_BUILD_EXAMPLES=OFF \
  -DGLFW_BUILD_TESTS=OFF \
  -DGLFW_BUILD_DOCS=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

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
setenv GLFW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
