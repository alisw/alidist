package: lz4
version: "%(tag_basename)s"
tag: v1.9.3
source: https://github.com/lz4/lz4
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
prefer_system: ".*"
prefer_system_check: |
  printf "#include <lz4.h>\n" | cc -xc -I$(brew --prefix lz4)/include - -c -M 2>&1
---

cmake -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_INSTALL_LIBDIR=lib          \
      $SOURCEDIR/build/cmake
make -j ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > "$MODULEDIR/$PKGNAME"
