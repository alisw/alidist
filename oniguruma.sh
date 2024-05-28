package: oniguruma
version: v6.9.5
tag: v6.9.5_rev1
source: https://github.com/kkos/oniguruma/
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
prefer_system: (?!slc5.*)
---
#!/bin/bash -e

# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete "$SOURCEDIR/" "$BUILDDIR"
cd "$BUILDDIR"
./autogen.sh
./configure --prefix="$INSTALLROOT"        \
            --enable-static                \
            --disable-shared               \
            --disable-dependency-tracking

make ${JOBS+-j $JOBS}
make install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
