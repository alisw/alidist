package: FairLogger
version: "%(tag_basename)s"
tag: v1.9.1
source: https://github.com/FairRootGroup/FairLogger
requires:
 - fmt
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
incremental_recipe: |
  cmake --build . --target install ${JOBS:+-- -j$JOBS}
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
prepend_path:
  ROOT_INCLUDE_PATH: "$FAIRLOGGER_ROOT/include"
---
#!/bin/bash

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FMT_ROOT ]] && FMT_ROOT=`brew --prefix fmt`
  ;;
  *) ;;
esac

mkdir -p $INSTALLROOT

cmake $SOURCEDIR                                                 \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                        \
      -DDISABLE_COLOR=ON                                         \
      -DUSE_EXTERNAL_FMT=ON                                      \
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . ${JOBS:+-- -j$JOBS}
ctest ${JOBS:+-j$JOBS}
cmake --build . --target install ${JOBS:+-- -j$JOBS}

# ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --extra > "etc/modulefiles/$PKGNAME" <<\EoF
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p $MODULEDIR && rsync -a --delete etc/modulefiles/ $MODULEDIR
