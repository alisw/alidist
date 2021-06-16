package: xalienfs
version: "%(tag_basename)s"
tag: v1.0.14r1-alice3
source: https://github.com/alisw/xalienfs.git
requires:
 - XRootD
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - AliEn-Runtime
build_requires:
 - "autotools:(slc6|slc7)"
 - SWIG
 - UUID
 - libperl
 - alibuild-recipe-tools
prepend_path:
 PERLLIB: "$ALIEN_RUNTIME_ROOT/lib/perl"
env:
  GSHELL_ROOT: "$XALIENFS_ROOT"
  GSHELL_NO_GCC: "1"
---
#!/bin/bash -e
[[ ! $SWIG_ROOT ]] && SWIG_LIB=`swig -swiglib`

rsync -a --delete --exclude='**/.git' --delete-excluded \
      $SOURCEDIR/ ./
./bootstrap.sh
autoreconf -ivf
case $ARCHITECTURE in
  osx*)
    [[ "$OPENSSL_ROOT" != "" ]] || OPENSSL_ROOT=`brew --prefix openssl`
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
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --extra > "$MODULEDIR/$PKGNAME" <<\EOF
setenv GSHELL_ROOT $PKG_ROOT
setenv GSHELL_NO_GCC 1
EOF
