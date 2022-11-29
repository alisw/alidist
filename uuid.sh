package: UUID
version: v2.27.1
tag: alice/v2.27.1
source: https://github.com/alisw/uuid
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "autotools:(slc6|slc7)"
prepend_path:
  PKG_CONFIG_PATH: "$UUID_ROOT/share/pkgconfig"
---
rsync -av --delete --exclude '**/.git' "$SOURCEDIR/" .
if [[ $AUTOTOOLS_ROOT == "" ]]  && which brew >/dev/null; then
  PATH=$PATH:$(brew --prefix gettext)/bin
fi

perl -p -i -e 's/AM_GNU_GETTEXT_VERSION\(\[0\.18\.3\]\)/AM_GNU_GETTEXT_VERSION([0.18.2])/' configure.ac

case $ARCHITECTURE in
  osx_*) disable_shared=yes ;;
  *) disable_shared= ;;
esac

autoreconf -ivf
./configure ${disable_shared:+--disable-shared}   \
            "--libdir=$INSTALLROOT/lib"           \
            "--prefix=$INSTALLROOT"               \
            --disable-all-programs                \
            --disable-silent-rules                \
            --disable-tls                         \
            --disable-rpath                       \
            --without-ncurses                     \
            --enable-libuuid
make ${JOBS:+-j$JOBS} libuuid.la libuuid/uuid.pc install-uuidincHEADERS
mkdir -p "$INSTALLROOT/lib" "$INSTALLROOT/share/pkgconfig"
cp -a libuuid/uuid.pc "$INSTALLROOT/share/pkgconfig"
cp -a .libs/libuuid.a* "$INSTALLROOT/lib"
if [ -z "$disable_shared" ]; then
  cp -a .libs/libuuid.so* "$INSTALLROOT/lib"
fi
rm -rf "$INSTALLROOT/man"
