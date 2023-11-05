package: VMC
version: "%(tag_basename)s"
tag: "v2-0"
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

[ "0$ENABLE_VMC" == "0" ] && exit 0 || true
case $ARCHITECTURE in
  osx*) SONAME=dylib ;;
  *) SONAME=so ;;
esac

cmake "$SOURCEDIR"                                 \
      -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
      -DCMAKE_INSTALL_LIBDIR=lib                   \
      -DVDT_INCLUDE_DIR="$ROOT_ROOT/include"       \
      -DVDT_LIBRARY="$ROOT_ROOT/lib/libvdt.$SONAME"      \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${JOBS:+-j$JOBS} install

ln -s libVMCLibrary.$SONAME $INSTALLROOT/lib/libVMC.$SONAME
# update modulefile
cat >> "$MODULEFILE" <<EoF
# Our environment
set VMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VMC_ROOT \$VMC_ROOT
prepend-path LD_LIBRARY_PATH \$VMC_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$VMC_ROOT/include/vmc
EoF
