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
  osx_x86-64)
    [[ "$OPENSSL_ROOT" != "" ]] || OPENSSL_ROOT=`brew --prefix openssl@3`
    EXTRA_PERL_CXXFLAGS="-I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
  ;;
  osx_arm64)
    [[ "$OPENSSL_ROOT" != "" ]] || OPENSSL_ROOT=`brew --prefix openssl@3`
    EXTRA_PERL_CXXFLAGS="-I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
    export LDFLAGS="-L$(brew --prefix readline)/lib"
    export CPPFLAGS="-I$(brew --prefix readline)/include"
    export PKG_CONFIG_PATH="$(brew --prefix readline)/lib/pkgconfig"
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
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 XRootD/${XROOTD_VERSION}-${XROOTD_REVISION}             \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}   \\
            ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}

# Our environment
set XALIENFS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

setenv GSHELL_ROOT \$XALIENFS_ROOT
setenv GSHELL_NO_GCC 1

prepend-path LD_LIBRARY_PATH \$XALIENFS_ROOT/lib
prepend-path PATH \$XALIENFS_ROOT/bin
EoF
