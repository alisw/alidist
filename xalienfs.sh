package: xalienfs
version: "%(tag_basename)s"
tag: alice/v1.0.14r1
source: https://github.com/alisw/xalienfs.git
build_requires:
 - autotools
 - XRootD
 - SWIG
 - UUID
---
#!/bin/bash -e
rsync -a --delete --exclude='**/.git' --delete-excluded \
      $SOURCEDIR/ ./
./bootstrap.sh
autoreconf -ivf
export CFLAGS="-I$XROOTD_ROOT/include -I$XROOTD_ROOT/include/xrootd/private"
case $ARCHITECTURE in
  osx*)
    CFLAGS="$CFLAGS -I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
  ;;
esac
export CPPFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$XROOTD_ROOT/lib -L$UUID_ROOT/lib"
./configure --prefix=$INSTALLROOT                    \
            --with-xrootd-location=$XROOTD_ROOT      \
            --enable-perl-module                     \
            --with-perl=perl                         \
            ${SWIG_INC:+--with-swig-inc="$SWIG_INC"} \
            --enable-build-server                    \
            --disable-readline
# May not work in multicore
make
make install INSTALLSITEARCH=$INSTALLROOT/lib/perl \
             INSTALLARCHLIB=$INSTALLROOT/lib/perl
