package: librdkafka
version: "%(tag_basename)s"
tag: v2.3.0
requires:
  - "GCC-Toolchain:(?!osx)"
  - lz4
  - zlib
build_requires:
  - alibuild-recipe-tools
  - CMake
  - ninja
source: https://github.com/edenhill/librdkafka
---

cmake ${SOURCEDIR}                                                                                  \
      -DWITH_SSL=OFF                                                                                \
      -DWITH_CURL=OFF                                                                               \
      -DRDKAFKA_BUILD_EXAMPLES=OFF                                                                  \
      -DRDKAFKA_BUILD_TESTS=OFF                                                                     \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                         \
      -G Ninja                                                                                      \

cmake --build . -- ${JOBS:+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"
cat >> "etc/modulefiles/$PKGNAME" <<EoF
EoF
mkdir -p "$INSTALLROOT/etc/modulefiles" && rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
