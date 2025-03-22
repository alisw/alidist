package: FairCMakeModules
version: "%(tag_basename)s"
tag: v1.0.0
source: https://github.com/FairRootGroup/FairCMakeModules
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/sh

cmake -S "$SOURCEDIR" -B .                                        \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                       \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                   \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . --target install ${JOBS:+-- -j$JOBS}

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --cmake > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
