package: clang-build-analyser
version: "%(tag_basename)s"
tag: v1.6.0
source: https://github.com/aras-p/ClangBuildAnalyzer.git
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
---

cmake -S $SOURCEDIR \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin > "$MODULEFILE"
