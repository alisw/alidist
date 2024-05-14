package: libuv
version: v1.40.0
source: https://github.com/libuv/libuv
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$LIBUV_ROOT/lib/pkgconfig"
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include <uv/version.h>\n#if UV_VERSION_HEX < 0x12a00\n#error libuv >=1.40.0 required\n#endif\n" | c++ -I$(brew --prefix libuv)/include -xc++ - -c -o /dev/null 2>&1
---
#!/bin/sh
cmake $SOURCEDIR                                             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                    \
      -DCMAKE_INSTALL_LIBDIR=lib

make ${JOBS+-j $JOBS}
make install

mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
