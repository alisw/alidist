package: librdkafka
version: "%(tag_basename)s"
tag: v1.2.1-RC1
requires:
  - "GCC-Toolchain:(?!osx)"
  - lz4
build_requires:
  - CMake
source: https://github.com/edenhill/librdkafka
---
#!/bin/bash -ex
cmake -H"$SOURCEDIR"                        \
      -B"$SOURCEDIR/_cmake_build"           \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "$SOURCEDIR/_cmake_build" --target install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$BASEDIR/$PKGNAME/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
