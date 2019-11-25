package: xalienfs
version: "%(tag_basename)s"
tag: v1.0.14r1-alice3
source: https://github.com/alisw/xalienfs.git
build_requires:
 - autotools
 - XRootD
 - SWIG
 - UUID
 - libperl
---
#!/bin/bash -e
[[ ! $SWIG_ROOT ]] && SWIG_LIB=`swig -swiglib`

rsync -a --delete --exclude='**/.git' --delete-excluded \
      $SOURCEDIR/ ./
./bootstrap.sh
autoreconf -ivf
case $ARCHITECTURE in
  osx*)
    EXTRA_PERL_CXXFLAGS="-I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
  ;;
esac
export CXXFLAGS="$CXXFLAGS -I$XROOTD_ROOT/include -I$XROOTD_ROOT/include/xrootd/private \
                 ${UUID_ROOT:+-I$UUID_ROOT/include -L$UUID_ROOT/lib}                    \
                 ${OPENSSL_ROOT:+-I$OPENSSL_ROOT/include -L$OPENSSL_ROOT/lib}           \
                 $EXTRA_PERL_CXXFLAGS"
./configure --prefix=$INSTALLROOT                \
            --with-xrootd-location=$XROOTD_ROOT  \
            --enable-perl-module                 \
            --with-perl=perl                     \
            --with-swig-inc="$SWIG_LIB"          \
            --enable-build-server
# May not work in multicore
make
make install INSTALLSITEARCH=$INSTALLROOT/lib/perl \
             INSTALLARCHLIB=$INSTALLROOT/lib/perl

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ROOT/${ROOT_VERSION}-${ROOT_REVISION}

# Our environment
set XALIENFS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$XALIENFS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$XALIENFS_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
