package: Clang
version: "v13.0.0"
tag: "llvmorg-13.0.0"
source: https://github.com/llvm/llvm-project
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
 - "Python:slc.*"
 - "Python-system:(?!slc.*)"
 - CMake
 - curl
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
  osx_*) DEFAULT_SYSROOT=$(xcrun --show-sdk-path) ;;
  *) DEFAULT_SYSROOT= ;;
esac
case $ARCHITECTURE in
  *_x86-64) LLVM_TARGETS_TO_BUILD=X86 ;;
  *_arm64) LLVM_TARGETS_TO_BUILD=AArch64 ;;
  *) echo 'Unknown LLVM target for architecture' >&2; exit 1 ;;
esac

# BUILD_SHARED_LIBS=ON is needed for e.g. adding dynamic plugins to clang-tidy.
# Arrow v9 needs LLVM_ENABLE_RTTI=ON.
cmake $SOURCEDIR/llvm \
  -G Ninja \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
  -DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS_TO_BUILD:?}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_INSTALL_UTILS=ON \
  -DPYTHON_EXECUTABLE=$(which python3) \
  -DDEFAULT_SYSROOT="$DEFAULT_SYSROOT" \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DLLVM_ENABLE_RTTI=ON \
  -DBUILD_SHARED_LIBS=OFF

cmake --build . -- ${JOBS:+-j$JOBS} install

git clone -b $PKGVERSION https://github.com/KhronosGroup/SPIRV-LLVM-Translator
mkdir SPIRV-LLVM-Translator/build
pushd SPIRV-LLVM-Translator/build
cmake ../ \
  -G Ninja \
  -DLLVM_DIR="$INSTALLROOT/lib/cmake/llvm" \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"
cmake --build . -- ${JOBS:+-j$JOBS} install
popd

case $ARCHITECTURE in
  osx*)
    # Add correct rpath to dylibs on Mac as long as there is no better way to
    # control rpath in the LLVM CMake.
    # Add rpath to all libraries in lib and change their IDs to be absolute paths.
    find "$INSTALLROOT/lib" -name '*.dylib' -not -name '*ios*.dylib' \
         -exec install_name_tool -add_rpath "$INSTALLROOT/lib" '{}' \; \
         -exec install_name_tool -id '{}' '{}' \;
    # In lib/clang/*/lib/darwin, the relative rpath is wrong and needs to be
    # corrected from "@loader_path/../lib" to "@loader_path/../darwin".
    find "$INSTALLROOT"/lib/clang/*/lib/darwin -name '*.dylib' -not -name '*ios*.dylib' \
         -exec install_name_tool -rpath '@loader_path/../lib' '@loader_path/../darwin' '{}' \;

    # Needed to be able to find C++ headers.
    ln -sf "$(xcrun --show-sdk-path)/usr/include/c++" "$INSTALLROOT/include/c++" ;;
esac

# We do not want to have the clang executables in path
# to avoid issues with system clang on macOS.
# We **MUST NOT** add bin-safe to the build path. Runtime
# path is fine.
mkdir $INSTALLROOT/bin-safe
mv $INSTALLROOT/bin/llvm-spirv* $INSTALLROOT/bin/clang* $INSTALLROOT/bin-safe/
sed -i.bak -e "s|bin/clang|bin-safe/clang|g" -e "s|bin/llvm-spirv|bin-safe/llvm-spirv|g" $INSTALLROOT/lib/cmake/clang/ClangTargets-release.cmake
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
