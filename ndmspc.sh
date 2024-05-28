package: ndmspc
version: "%(tag_basename)s"
tag: "v0.20240422.0"
requires:
  - ROOT
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://gitlab.com/ndmspc/ndmspc.git
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
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
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build . -- ${JOBS+-j $JOBS} install

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
setenv NDMSPC_MACRO_DIR \$PKG_ROOT/macros
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
