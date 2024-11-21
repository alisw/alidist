package: libffi
version: v3.2.1-alice1
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
source: https://github.com/alisw/libffi
prepend_path:
  LD_LIBRARY_PATH: "$LIBFFI_ROOT/lib64"
---
#!/bin/bash -ex
rsync -a "$SOURCEDIR"/ .
autoreconf -ivf .

# Hack to bypass automake 1.17 creating a malformed Makefile on macOS
# https://github.com/libffi/libffi/issues/853
mv -f Makefile_3.2.1_autoconf_2.69.in Makefile.in

MAKEINFO=: ./configure --prefix="$INSTALLROOT" --libdir=$INSTALLROOT/lib --disable-docs --disable-multi-os-directory
make ${JOBS:+-j $JOBS} MAKEINFO=:
make install MAKEINFO=:

[ -d "$INSTALLROOT/lib64" ] && rsync -av "$INSTALLROOT/lib64/" "$INSTALLROOT/lib/" && rm -rf "$INSTALLROOT/lib64"

# Do not install info documentation
rm -fr "$INSTALLROOT/share/info"

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
