package: o2codechecker
version: v20.1.7-alice1
tag: v20.1.7-alice1
requires:
  - Clang:(?!osx*)
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
source: https://github.com/AliceO2Group/O2CodeChecker.git
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # use compatible llvm@20 from brew, if available. This
    # must match the prefer_system_check in clang.sh
    CLANG_ROOT=`brew --prefix llvm@20`
  ;;
    *) ;;
esac
cmake $SOURCEDIR -G Ninja                                \
                 -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE    \
                 -DClang_DIR=$CLANG_ROOT/lib/cmake/clang \
                 -DLLVM_DIR=$CLANG_ROOT/lib/cmake/llvm
cmake --build . -- ${JOBS:+-j$JOBS} install
ctest

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --cmake > "etc/modulefiles/$PKGNAME"

cat >> "etc/modulefiles/$PKGNAME" <<EoF
setenv O2CODECHECKER_ROOT \$O2CODECHECKER_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
