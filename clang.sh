package: Clang
version: "7.0.0"
tag: v7.0.0-alice1
source: https://github.com/alisw/clang
requires:
 - Python
 - "GCC-Toolchain:(?!osx)"
build_requires:
 - CMake
---
#!/bin/sh

# Unsetting default compiler flags in order to make sure that no debug
# information is compiled into the objects which make the build artifacts very
# big
unset CXXFLAGS
unset CFLAGS

# note that BUILD_SHARED_LIBS=ON IS NEEDED FOR ADDING DYNAMIC PLUGINS
# to clang-tidy (for instance)
cmake $SOURCEDIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_INSTALL_UTILS=ON \
  -DPYTHON_EXECUTABLE=$(which python3) \
  -DBUILD_SHARED_LIBS=ON

make ${JOBS+-j $JOBS}
make install
case $ARCHITECTURE in
  osx*)
    ln -sf /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++ $INSTALLROOT/include
  ;;
esac

curl -o $INSTALLROOT/bin/git-clang-format https://llvm.org/svn/llvm-project/cfe/trunk/tools/clang-format/git-clang-format
chmod u+x $INSTALLROOT/bin/git-clang-format

find $SOURCEDIR/tools/clang/tools/scan-build -type f -perm /111 -exec cp {} $INSTALLROOT/bin \;
find $SOURCEDIR/tools/clang/tools/scan-view -type f -perm /111 -exec cp {} $INSTALLROOT/bin \;

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
module load BASE/1.0                                                          \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv CLANG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CLANG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(CLANG_ROOT)/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
