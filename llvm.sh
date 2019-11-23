package: LLVM
version: "v7.1.0"
tag: "llvmorg-7.1.0"
source: https://github.com/llvm/llvm-project
requires:
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
  osx*) DEFAULT_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk ;;
  *) DEFAULT_SYSROOT="" ;;
esac

cmake ${SOURCEDIR}/llvm                                             \
  -DCMAKE_BUILD_TYPE=Release                                        \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"                        \
  -DCMAKE_CXX_FLAGS=-fvisibility=hidden                             \
  -DLLVM_INSTALL_UTILS=OFF                                          \
  -DBUILD_SHARED_LIBS=OFF                                           \
  -DDEFAULT_SYSROOT=OFF                                             \
  -DLLVM_ENABLE_PROJECTS="clang"                                    \
  -DLLVM_TARGETS_TO_BUILD="X86"                                     \
  -DLLVM_INCLUDE_TESTS=OFF                                          \
  -DCLANG_INCLUDE_TESTS=OFF                                         \
  -DLLVM_INCLUDE_EXAMPLES=OFF                                       \
  -DCLANG_TOOL_ARCMT_TEST_BUILD=OFF                                 \
  -DCLANG_TOOL_CLANG_CHECK_BUILD=OFF                                \
  -DCLANG_TOOL_CLANG_FORMAT_BUILD=OFF                               \
  -DCLANG_TOOL_CLANG_FORMAT_VS_BUILD=OFF                            \
  -DCLANG_TOOL_CLANG_FUZZER_BUILD=OFF                               \
  -DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF                          \
  -DCLANG_TOOL_CLANG_OFFLOAD_BUNDLER_BUILD=OFF                      \
  -DCLANG_TOOL_CLANG_RENAME_BUILD=OFF                               \
  -DCLANG_TOOL_C_ARCMT_TEST_BUILD=OFF                               \
  -DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF                               \
  -DCLANG_TOOL_DIAGTOOL_BUILD=OFF                                   \
  -DCLANG_TOOL_LIBCLANG_BUILD=OFF                                   \
  -DCLANG_TOOL_SCAN_BUILD_BUILD=OFF                                 \
  -DCLANG_TOOL_SCAN_VIEW_BUILD=OFF                                  \
  -DLLVM_TOOL_LLVM_AR_BUILD=OFF                                     \
  -DLLVM_BUILD_TOOLS=OFF                                            \
  -DCLANG_ENABLE_STATIC_ANALYZER=OFF                                \
  -DCLANG_ENABLE_ARCMT=OFF                                          \
  -DCLANG_ENABLE_FORMAT=OFF                                         \
  ${GCC_TOOLCHAIN_ROOT:+-DGCC_INSTALL_PREFIX=${GCC_TOOLCHAIN_ROOT}} \
  -DDEFAULT_SYSROOT=${DEFAULT_SYSROOT}                              \
  -DPYTHON_EXECUTABLE=$(which python)

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
