package: o2codechecker
version: v18.1.2
tag: v18.1.2
requires:
  - Clang:(?!osx*)
build_requires:
  - CMake
source: https://github.com/AliceO2Group/O2CodeChecker.git
incremental_recipe: |
  make ${JOBS+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
case $ARCHITECTURE in
    osx*)
	CLANG_ROOT=`brew --prefix llvm`
	;;
    *)
	;;
esac
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE    \
                 -DClang_DIR=$CLANG_ROOT/lib/cmake/clang \
                 -DLLVM_DIR=$CLANG_ROOT/lib/cmake/llvm
make ${JOBS+-j$JOBS} install
ctest

# Modulefile
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
module load BASE/1.0 ${CLANG_REVISION:+Clang/$CLANG_VERSION-$CLANG_REVISION}
# Our environment
set O2CODECHECKER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2CODECHECKER_ROOT \$O2CODECHECKER_ROOT
prepend-path PATH \$O2CODECHECKER_ROOT/bin
prepend-path LD_LIBRARY_PATH \$O2CODECHECKER_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
