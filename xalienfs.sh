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
CXXFLAGS="$CXXFLAGS -I$XROOTD_ROOT/include -I$XROOTD_ROOT/include/xrootd/private \
          ${UUID_ROOT:+-I$UUID_ROOT/include -L$UUID_ROOT/lib} "
case $ARCHITECTURE in
  osx*)
    CXXFLAGS="$CXXFLAGS -I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
  ;;
esac
export CXXFLAGS
./configure --prefix=$INSTALLROOT                    \
            --with-xrootd-location=$XROOTD_ROOT      \
            --enable-perl-module                     \
            --with-perl=perl                         \
            ${SWIG_LIB:+--with-swig-inc="$SWIG_LIB"} \
            --enable-build-server
# May not work in multicore
make
make install INSTALLSITEARCH=$INSTALLROOT/lib/perl \
             INSTALLARCHLIB=$INSTALLROOT/lib/perl
