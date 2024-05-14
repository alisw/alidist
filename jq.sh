package: jq
version: v1.6-alice1
tag: 52d5988
source: https://github.com/stedolan/jq.git
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - oniguruma
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
prefer_system: (?!slc5.*)
prefer_system_check: |
  type jq
---
#!/bin/bash -e
# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete "$SOURCEDIR/" "$BUILDDIR"
cd "$BUILDDIR"
autoreconf -iv
./configure --prefix="$INSTALLROOT"        \
            --enable-static                \
            --disable-shared               \
            --disable-maintainer-mode      \
            --with-oniguruma="$ONIGURUMA_ROOT" \
            --disable-dependency-tracking

make ${JOBS+-j $JOBS}
make install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
