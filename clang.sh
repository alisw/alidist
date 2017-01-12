package: Clang
version: "3.9"
source: https://github.com/alisw/clang
tag: master
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
  -DBUILD_SHARED_LIBS=ON

make ${JOBS+-j $JOBS}
make install
case $ARCHITECTURE in
  osx*)
    ln -sf /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++ $INSTALLROOT/include
  ;;
esac
find $SOURCEDIR/tools/clang/tools/scan-build -type f -perm +111 -exec cp {} $INSTALLROOT/bin \;
find $SOURCEDIR/tools/clang/tools/scan-view -type f -perm +111 -exec cp {} $INSTALLROOT/bin \;

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
module load BASE/1.0
# Our environment
setenv CLANG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CLANG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(CLANG_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(CLANG_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
