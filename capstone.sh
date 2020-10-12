package: capstone
version: "4.0.2"
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/aquynh/capstone
---
cmake $SOURCEDIR                          \
      -DCAPSTONE_ARCHITECUTRE_DEFAULT=OFF \
      -DCAPSTONE_BUILD_SHARED=OFF         \
      -DCMAKE_INSTALL_LIBDIR=lib          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
