package: treelite
version: "%(tag_basename)s"
tag: "df6a892b7faf532aea13bacc0f30b8a4743f82cf"
source: https://github.com/dmlc/treelite
requires:
  - "GCC-Toolchain:(?!osx)"
  - fmt
  - RapidJSON
license: Apache-2.0
build_requires:
  - CMake
  - "Xcode:(osx.*)"
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $FMT_ROOT ]] && FMT_ROOT=`brew --prefix fmt`
  ;;
  *) ;;
esac

rsync -a $SOURCEDIR/ src/
pushd src
  sed -i.deleteme "s/RAPIDJSON_INCLUDE_DIRS/RapidJSON_INCLUDE_DIRS/g" cmake/ExternalLibs.cmake
popd

cmake src                                   \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.27       \
  -DCMAKE_INSTALL_LIBDIR:PATH=lib           \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"     \
  -DUSE_OPENMP=OFF

cmake --build . -- ${JOBS:+-j$JOBS} install

[[ -d $INSTALLROOT/lib64 ]] && [[ ! -d $INSTALLROOT/lib ]] && ln -sf ${INSTALLROOT}/lib64 $INSTALLROOT/lib

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
set TREELITE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$TREELITE_ROOT/bin
prepend-path ROOT_INCLUDE_PATH \$TREELITE_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$TREELITE_ROOT/runtime/native/include
prepend-path LD_LIBRARY_PATH \$TREELITE_ROOT/lib
EoF
