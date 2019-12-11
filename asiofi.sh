package: asiofi
version: "%(tag_basename)s"
tag: v0.3.1
source: https://github.com/FairRootGroup/asiofi
requires:
  - boost
  - ofi
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
incremental_recipe: |
  cmake --build . --target install ${JOBS:+-- -j$JOBS}
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
mkdir -p $INSTALLROOT

cmake $SOURCEDIR                                                 \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                        \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_INSTALL_LIBDIR=lib                                 \
      -DCMAKE_INSTALL_BINDIR=bin                                 \
      -DDISABLE_COLOR=ON                                         \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                    \
      ${OFI_ROOT:+-DOFI_ROOT=$OFI_ROOT}                          \
      -DBUILD_TESTING=ON


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
module load BASE/1.0                                                                            \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            ${BOOST_ROOT:+boost/$BOOST_VERSION-$BOOST_REVISION}                                 \\
            ${OFI_ROOT:+ofi/$OFI_VERSION-$OFI_REVISION}
# Our environment
set ASIOFI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$ASIOFI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ASIOFI_ROOT/lib
EoF
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p $MODULEDIR && rsync -a --delete etc/modulefiles/ $MODULEDIR

