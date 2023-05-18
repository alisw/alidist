package: libunwind
version: v1.6.2
source: http://github.com/libunwind/libunwind
build_requires:
  - libatomic_ops
  - alibuild-recipe-tools
---
#!/bin/sh
(cd $SOURCEDIR && autoreconf -i)
$SOURCEDIR/configure \
  CPPFLAGS="-I$LIBATOMIC_OPS_ROOT/include" \
  CFLAGS="-g -O3" \
  --prefix=$INSTALLROOT \
  --disable-block-signals

make ${JOBS+-j $JOBS}
make install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
