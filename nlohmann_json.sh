package: nlohmann_json
version: "v3.11.3"
tag: v3.11.3
source: https://github.com/nlohmann/json
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prefer_system: .*
prefer_system_check: |
  printf "#include <nlohmann/json_fwd.hpp>\n" | cc -xc++ - -I"$(brew --prefix nlohmann-json)/include" -c -o /dev/null
---
#!/bin/bash -e
  cmake "$SOURCEDIR"                             \
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DJSON_BuildTests=OFF                          \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat << EOF >> "$MODULEFILE"
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
