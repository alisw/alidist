package: TBB
version: "v2021.5.0"
tag: v2021.5.0
source: https://github.com/uxlfoundation/oneTBB
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
prefer_system: .*
prefer_system_check: |
  printf "#include <tbb/concurrent_unordered_map.h>\n static_assert(TBB_INTERFACE_VERSION >= 11009, \"min version check failed\");\n" | c++ -std=c++20 -xc++ - -I$(brew --prefix tbb)/include -c -o /dev/null
prepend_path:
  ROOT_INCLUDE_PATH: "$TBB_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT   \
          ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}      \
          -DCMAKE_INSTALL_LIBDIR=lib -DTBB_TEST=OFF

# Build and install
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
set TBB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$TBB_ROOT/include
EOF

