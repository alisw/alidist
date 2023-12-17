package: FairLogger
version: "%(tag_basename)s"
tag: v1.11.1
source: https://github.com/FairRootGroup/FairLogger
requires:
  - fmt
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
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
      -DPROJECT_GIT_VERSION=$(echo $PKGVERSION | sed -e 's/v//') \
      -DBUILD_TESTING=OFF                                        \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                        \
      -DDISABLE_COLOR=ON                                         \
      -DUSE_EXTERNAL_FMT=ON                                      \
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . ${JOBS:+-- -j$JOBS}
ctest ${JOBS:+-j$JOBS}
cmake --build . --target install ${JOBS:+-- -j$JOBS}

# ModuleFile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0                                        \
       ${FMT_REVISION:+fmt/${FMT_VERSION}-${FMT_REVISION}}
# Our environment
set FAIRLOGGER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$FAIRLOGGER_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$FAIRLOGGER_ROOT/include
EoF
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p $MODULEDIR && rsync -a --delete etc/modulefiles/ $MODULEDIR
