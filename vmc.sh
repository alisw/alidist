package: VMC
version: "%(tag_basename)s"
tag: "v1-1-p1"
source: https://github.com/vmc-project/vmc
requires:
  - ROOT
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$VMC_ROOT/include/vmc"
---
#!/bin/bash -e

# Make basic modufile first
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > $MODULEFILE

# Only really build for ROOT version 6, for ROOT5 we always use builtin VMC
case ${ROOT_VERSION} in
  v6*) cmake "$SOURCEDIR"                                 \
             -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
             -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
             -DCMAKE_INSTALL_LIBDIR=lib                   \
             ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

       cmake --build . -- ${JOBS:+-j$JOBS} install

       # Make backward compatible in case a depending (older) package still needs libVMC.so
       ln -s $INSTALLROOT/lib/libVMCLibrary.so $INSTALLROOT/lib/libVMC.so

       # update modulefile
       cat >> "$MODULEFILE" <<EoF
       set VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
       setenv VMC_ROOT \$VMC_ROOT
       prepend-path LD_LIBRARY_PATH \$VMC_ROOT/lib
       prepend-path ROOT_INCLUDE_PATH \$VMC_ROOT/include/vmc
EoF
  ;;
  *) echo "Not building for ROOT version different from v6*"
  ;;
esac
