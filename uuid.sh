package: UUID
version: v2.27.1
source: https://kernel.googlesource.com/pub/scm/utils/util-linux/util-linux.git
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - autotools
---
#!/bin/sh
rsync -av --delete --exclude "**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure $([[ ${ARCHITECTURE:0:3} == osx ]] && echo --disable-shared) \
            --libdir=$INSTALLROOT/lib \
            --prefix=$INSTALLROOT \
            --disable-silent-rules \
            --disable-tls \
            --disable-rpath \
            --disable-libblkid \
            --disable-libmount \
            --disable-mount \
            --disable-losetup \
            --disable-fsck \
            --disable-partx \
            --disable-mountpoint \
            --disable-fallocate \
            --disable-unshare \
            --disable-eject \
            --disable-agetty \
            --disable-cramfs \
            --disable-wdctl \
            --disable-switch_root \
            --disable-pivot_root \
            --disable-kill \
            --disable-utmpdump \
            --disable-rename \
            --disable-login \
            --disable-sulogin \
            --disable-su \
            --disable-schedutils \
            --disable-wall \
            --disable-makeinstall-setuid \
            --without-ncurses \
            --enable-libuuid
make ${JOBS:+-j$JOBS} uuidd
mkdir -p $INSTALLROOT/lib
cp -p .libs/libuuid.a* $INSTALLROOT/lib
if [[ ${ARCHITECTURE:0:3} != osx ]]; then
  cp -p .libs/libuuid.so* $INSTALLROOT/lib
fi
mkdir -p $INSTALLROOT/include
make install-uuidincHEADERS
rm -rf $INSTALLROOT/man
