package: opentelemetry-cpp
version: "%(tag_basename)s"
tag: "v1.22.0"
requires:
  - curl
  - protobuf
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/open-telemetry/opentelemetry-cpp.git
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                   \
      -DWITH_BENCHMARK=OFF                                        \
      -DBUILD_TESTING=OFF                                         \
      -DWITH_EXAMPLES=OFF                                         \
      -DWITH_OTLP_FILE=ON                                         \
      -DWITH_OTLP_HTTP=ON                                         \
      -DBUILD_SHARED_LIBS=ON                                      \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

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
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
