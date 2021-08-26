package: Clang
version: "v12.0.1"
tag: "llvmorg-12.0.1"
source: https://github.com/llvm/llvm-project
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
 - "Python:slc.*"
 - "Python-system:(?!slc.*)"
 - CMake
 - system-curl
 - ninja
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
    if [ "X$DEFAULT_SYSROOT" = X ]; then
      DEFAULT_SYSROOT=`xcrun --show-sdk-path`
    fi
  ;;
  # This will most likely fail if we start producing binary packages for Ubuntu, but for the moment we do not.
  ubuntu*) DEFAULT_SYSROOT="" ;;
  debian*) DEFAULT_SYSROOT="" ;;
  unknown*) DEFAULT_SYSROOT="" ;;
  *) DEFAULT_SYSROOT="" ;;
esac
# note that BUILD_SHARED_LIBS=ON IS NEEDED FOR ADDING DYNAMIC PLUGINS
# to clang-tidy (for instance)
cmake $SOURCEDIR/llvm \
  -G Ninja \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_INSTALL_UTILS=ON \
  -DPYTHON_EXECUTABLE=$(which python3) \
  -DDEFAULT_SYSROOT=${DEFAULT_SYSROOT} \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DBUILD_SHARED_LIBS=OFF

cmake --build . -- ${JOBS:+-j$JOBS} install

#add correct rpath to dylibs on mac as long as there is no better way to controll rpath in the LLVM CMake.
case $ARCHITECTURE in
  osx*)
  # add rpath to all libraries in lib and change their IDs to be absolute paths
  find ${INSTALLROOT}/lib -name "*.dylib" ! -name "*ios*.dylib" -exec install_name_tool -add_rpath "${INSTALLROOT}/lib" {} \; -exec install_name_tool -id {} {} \;
  # in lib/clang/*/lib/darwin, the relative rpath is wrong and needs to be corrected from "@loader_path/../lib" to "@loader_path/../darwin" 
  find ${INSTALLROOT}/lib/clang/*/lib/darwin \( -name "*.dylib" -a \( ! -name "*ios*.dylib" \) \) -exec install_name_tool -add_rpath "@loader_path/../darwin" {} \;
  ;;
esac

# Needed to be able to find C++ headers.
case $ARCHITECTURE in
  osx*)
    ln -sf "$(find `xcode-select -p` -type d -path "*MacOSX.sdk/usr/include/c++" -o -path "*/XcodeDefault.xctoolchain/usr/include/c++" | head -1)" "$INSTALLROOT/include/c++"
  ;;
  *)
  if [ "X$GCC_TOOLCHAIN_ROOT" = X ]; then
    find $GCC_TOOLCHAIN_ROOT -type d -path "*/include/c++" -exec ln -sf {} $INSTALLROOT/include/c++ \;
  fi
  ;;
esac

# We do not want to have the clang executables in path
# to avoid issues with system clang on macOS.
# We **MUST NOT** add bin-safe to the build path. Runtime
# path is fine.
mkdir $INSTALLROOT/bin-safe
mv $INSTALLROOT/bin/clang* $INSTALLROOT/bin-safe/
sed -i.bak -e "s|bin/clang|bin-safe/clang|g" $INSTALLROOT/lib/cmake/clang/ClangTargets-release.cmake
rm $INSTALLROOT/lib/cmake/clang/*.bak

# Check it actually works
cat << \EOF > test.cc
#include <iostream>
EOF
$INSTALLROOT/bin-safe/clang++ -v -c test.cc

curl -o $INSTALLROOT/bin-safe/git-clang-format https://raw.githubusercontent.com/llvm/llvm-project/main/clang/tools/clang-format/git-clang-format
chmod u+x $INSTALLROOT/bin-safe/git-clang-format

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
set CLANG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$CLANG_ROOT/bin-safe
prepend-path LD_LIBRARY_PATH \$CLANG_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
