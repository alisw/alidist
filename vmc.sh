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

root_version=$(root-config --version)
root_version=${root_version:0:1}

if (( ${root_version} == 6 )) ; then
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    -DCMAKE_INSTALL_LIBDIR=lib                   \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

  cmake --build . -- ${JOBS:+-j$JOBS} install
  ln -s $INSTALLROOT/lib/libVMCLibrary.so $INSTALLROOT/lib/libVMC.so

  # Modulefile
  MODULEDIR="$INSTALLROOT/etc/modulefiles"
  MODULEFILE="$MODULEDIR/$PKGNAME"
  mkdir -p "$MODULEDIR"
  alibuild-generate-module --bin --lib > $MODULEFILE
  cat >> "$MODULEFILE" <<EoF
  setenv VMC_ROOT \$PKG_ROOT
  prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/vmc
EoF

else
  # Only modulefile, nothing else
  MODULEDIR="$INSTALLROOT/etc/modulefiles"
  MODULEFILE="$MODULEDIR/$PKGNAME"
  mkdir -p "$MODULEDIR"
  alibuild-generate-module > $MODULEFILE
fi
