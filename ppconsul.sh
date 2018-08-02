package: Ppconsul
version: 0.0.2
tag: f39961cdcfddc630616658fc9c1e833b51cba21b
source: https://github.com/oliora/ppconsul
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
---
#!/bin/bash -e

if [[ CMAKE_GENERATOR == Ninja && ! $NINJA_REVISION ]]; then
  unset CMAKE_GENERATOR
fi

cmake $SOURCEDIR                                 \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DCMAKE_INSTALL_LIBDIR=lib                 \
      -DBUILD_SHARED_LIBS=ON                     \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}
cmake --build . -- ${JOBS:+-j$JOBS} install

mkdir -p "$INSTALLROOT/etc/modulefiles"
cat > "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set PPCONSUL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$PPCONSUL_ROOT/lib
EoF
