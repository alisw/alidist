package: capstone
version: "6.0.0.Alpha4-alice1"
tag: 42fbce6c524a3a57748f9de2b5460a7135e236c1
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
source: https://github.com/aquynh/capstone
prepend_path:
  PKG_CONFIG_PATH: "$CAPSTONE_ROOT/lib/pkgconfig"
---
cmake $SOURCEDIR                          \
      -G Ninja                            \
      -DCAPSTONE_ARCHITECUTRE_DEFAULT=OFF \
      -DCAPSTONE_BUILD_SHARED=OFF         \
      -DCMAKE_INSTALL_LIBDIR=lib          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
