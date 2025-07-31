package: Clang
version: "v20.1.7"
tag: "llvmorg-20.1.7-alice2"
source: https://github.com/alisw/llvm-project-reduced
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "Python"
  - CMake
  - curl
  - ninja
env:
  LLVM_ROOT: "$CLANG_ROOT" # needed by LLVMAlt
prefer_system: (osx.*)
prefer_system_check: |
  brew --prefix llvm@18 && test -d $(brew --prefix llvm@18)
---
#!/bin/bash -e

# Unsetting default compiler flags in order to make sure that no debug
# information is compiled into the objects which make the build artifacts very
# big.
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
  *_aarch64) LLVM_TARGETS_TO_BUILD=AArch64 ;;
  *) echo 'Unknown LLVM target for architecture' >&2; exit 1 ;;
esac

# BUILD_SHARED_LIBS=ON is needed for e.g. adding dynamic plugins to clang-tidy.
# Apache Arrow needs LLVM_ENABLE_RTTI=ON.
cmake "$SOURCEDIR/llvm" \
  -G Ninja \
  -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;compiler-rt' \
  -DLLVM_ENABLE_RUNTIMES='libcxx;libcxxabi' \
  -DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS_TO_BUILD:?}" \
  -DCMAKE_BUILD_TYPE=Release \
  ${COMPILER_RT_OSX_ARCHS:+-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON} \
  ${COMPILER_RT_OSX_ARCHS:+-DCOMPILER_RT_OSX_ARCHS=${COMPILER_RT_OSX_ARCHS}} \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_INSTALL_UTILS=ON \
  -DPYTHON_EXECUTABLE="$(which python3)" \
  -DDEFAULT_SYSROOT="$DEFAULT_SYSROOT" \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DLLVM_ENABLE_RTTI=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=OFF 
  
cmake --build . -- ${JOBS:+-j$JOBS} install

if [[ $PKGVERSION == v18.1.* ]]; then
  SPIRV_TRANSLATOR_VERSION="v18.1.3"
elif [[ $PKGVERSION == v20.1.* ]]; then
  SPIRV_TRANSLATOR_VERSION="v20.1.3"
else
  SPIRV_TRANSLATOR_VERSION="${PKGVERSION%%.*}.0.0"
fi
git clone -b "$SPIRV_TRANSLATOR_VERSION" https://github.com/KhronosGroup/SPIRV-LLVM-Translator
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
mkdir "$INSTALLROOT/bin-safe"
mv "$INSTALLROOT"/bin/clang* "$INSTALLROOT/bin-safe/"
mv "$INSTALLROOT"/bin/llvm-spirv* "$INSTALLROOT/bin-safe/" # Install llvm-spirv tool
mv "$INSTALLROOT"/bin/git-clang* "$INSTALLROOT/bin-safe/"  # we also need git-clang-format in runtime
sed -i.bak -e "s|bin/clang|bin-safe/clang|g" "$INSTALLROOT/lib/cmake/clang/ClangTargets-release.cmake"
rm "$INSTALLROOT"/lib/cmake/clang/*.bak

# Allow clang to find our own GCC. Notice the cat does not expand variables because
# we want to resolve the environment when we run, not when we build this, to avoid
# relocation issues in case GCC and clang are not built at the same time.
if [ ! "X$GCC_TOOLCHAIN_ROOT" = X ]; then
  cat > "$INSTALLROOT/bin-safe/$(clang --print-target-triple)-clang++.cfg" << \EOF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EOF
  cat > "$INSTALLROOT/bin-safe/$(clang --print-target-triple)-clang.cfg" << \EOF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EOF
  cat > "$INSTALLROOT/bin-safe/$(clang --print-target-triple)-clang-cpp.cfg" << \EOF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EOF
fi

# Check it actually works
cat << \EOF > test.cc
#include <iostream>
EOF
"$INSTALLROOT/bin-safe/clang++" -v -c test.cc


# Modulefile
mkdir -p etc/modulefiles
cat > "etc/modulefiles/$PKGNAME" <<EoF
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
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
