package: RapidJSON
version: v1.1.0-alice2
tag: 091de040edb3355dcf2f4a18c425aec51b906f08
source: https://github.com/Tencent/rapidjson.git
build_requires:
  - CMake
  - ninja
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$RAPIDJSON_ROOT/include"
---
cmake $SOURCEDIR                                                       \
      -G Ninja                                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                              \
      -DCMAKE_POLICY_DEFAULT_CMP0077=NEW                               \
      -DRAPIDJSON_BUILD_TESTS=OFF                                      \
      -DRAPIDJSON_BUILD_EXAMPLES=OFF

ninja ${JOBS:+-j$JOBS} install

MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --cmake > $MODULEFILE
cat << EOF >> $MODULEFILE
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
