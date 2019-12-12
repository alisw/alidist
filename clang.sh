package: Clang
version: "v9.0.0"
tag: "llvmorg-9.0.0"
source: https://github.com/llvm/llvm-project
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
unset LDFLAGS

case $ARCHITECTURE in 
  # Needed to have the C headers
  osx*)
    XCODE_PATH=`xcode-select -p`
    DEFAULT_SYSROOT=$(find $XCODE_PATH -type d -path "*/MacOSX.sdk/usr/include" | sed -e 's|/usr/include||g')
  ;;
  *) DEFAULT_SYSROOT="" ;;
esac

# note that BUILD_SHARED_LIBS=ON IS NEEDED FOR ADDING DYNAMIC PLUGINS
# to clang-tidy (for instance)
cmake $SOURCEDIR/llvm \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_INSTALL_UTILS=ON \
  -DPYTHON_EXECUTABLE=$(which python3) \
  -DDEFAULT_SYSROOT=${DEFAULT_SYSROOT} \
  -DBUILD_SHARED_LIBS=ON

make ${JOBS+-j $JOBS}
make install

# Needed to be able to find C++ headers.
case $ARCHITECTURE in
  osx*)
    find `xcode-select -p` -type d -path "*usr/include/c++" -exec ln -sf {} $INSTALLROOT/include/c++ \;
  ;;
  *)
  if [ "X$GCC_TOOLCHAIN_ROOT" = X ]; then
    find $GCC_TOOLCHAIN_ROOT -type d -path "*/include/c++" -exec ln -sf {} $INSTALLROOT/include/c++ \;
  fi
  ;;
esac

# We do not want to have the clang executables in path
# to avoid issues with system clang on macOS.
mkdir $INSTALLROOT/bin-safe
mv $INSTALLROOT/bin/clang* $INSTALLROOT/bin-safe/
sed -i.bak -e "s|bin/clang|bin-safe/clang|g" $INSTALLROOT/lib/cmake/clang/ClangTargets-release.cmake
rm $INSTALLROOT/lib/cmake/clang/*.bak

# Check it actually works
cat << \EOF > test.cc
#include <iostream>
EOF
$INSTALLROOT/bin-safe/clang++ -v -c test.cc

curl -o $INSTALLROOT/bin/git-clang-format https://llvm.org/svn/llvm-project/cfe/trunk/tools/clang-format/git-clang-format
chmod u+x $INSTALLROOT/bin/git-clang-format

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
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} 
# Our environment
set CLANG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$CLANG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CLANG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
