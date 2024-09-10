package: Catch2
version: "%(tag_basename)s"
tag: v3.7.0
source: https://github.com/catchorg/Catch2
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
prepend_path:
  PKG_CONFIG_PATH: "$CATCH2_ROOT/share/pkgconfig"
---
cmake "$SOURCEDIR"                                  \
      -DCMAKE_CXX_STANDARD=20                       \
      -DCMAKE_INSTALL_LIBDIR=lib                    \
      -DBUILD_SHARED_LIBS=ON                        \
      -GNinja -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"

cmake --build . --target install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --lib --cmake > "$MODULEFILE"
cat << EOF >> "$MODULEFILE"
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/share/pkgconfig
EOF
