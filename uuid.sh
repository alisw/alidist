package: UUID
version: v2.27.1
tag: alice/v2.27.1
source: https://github.com/alisw/uuid
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - autotools
---
rsync -av --delete --exclude "**/.git" $SOURCEDIR/ .
if [[ $AUTOTOOLS_ROOT == "" ]]  && which brew >/dev/null; then
  PATH=$PATH:`brew --prefix gettext`/bin
fi

perl -p -i -e 's/AM_GNU_GETTEXT_VERSION\(\[0\.18\.3\]\)/AM_GNU_GETTEXT_VERSION([0.18.2])/' configure.ac

autoreconf -ivf
./configure $([[ ${ARCHITECTURE:0:3} == osx ]] && echo --disable-shared)  \
            --libdir=$INSTALLROOT/lib                                     \
            --prefix=$INSTALLROOT                                         \
            --disable-all-programs                                        \
            --disable-silent-rules                                        \
            --disable-tls                                                 \
            --disable-rpath                                               \
            --without-ncurses                                             \
            --enable-libuuid
make ${JOBS:+-j$JOBS} libuuid.la
mkdir -p $INSTALLROOT/lib
cp -a .libs/libuuid.a* $INSTALLROOT/lib
if [[ ${ARCHITECTURE:0:3} != osx ]]; then
  cp -a .libs/libuuid.so* $INSTALLROOT/lib
fi
mkdir -p $INSTALLROOT/include
make install-uuidincHEADERS
rm -rf $INSTALLROOT/man
