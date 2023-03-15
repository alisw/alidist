package: xalienfs
version: "%(tag_basename)s"
tag: v1.0.14r1-alice3
source: https://github.com/alisw/xalienfs.git
requires:
  - zlib
  - libxml2
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - AliEn-CAs
  - ApMon-CPP
  - UUID
  - XRootD
build_requires:
  - "autotools:(slc6|slc7)"
  - SWIG
  - libperl
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
prepend_path:
  PERLLIB: "$ALIEN_RUNTIME_ROOT/lib/perl"
env:
  GSHELL_ROOT: "$XALIENFS_ROOT"
  GSHELL_NO_GCC: "1"
---
#!/bin/bash -e

[[ -z "${SWIG_ROOT}" ]] && SWIG_LIB="$(swig -swiglib)"

rsync -a --delete --exclude='**/.git' --delete-excluded \
      "${SOURCEDIR}/" ./
./bootstrap.sh
autoreconf -ivf
case $ARCHITECTURE in
  osx_x86-64)
    [[ -z "${OPENSSL_ROOT}" ]] && OPENSSL_ROOT=$(brew --prefix openssl@1.1)
    EXTRA_PERL_CXXFLAGS="-I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
  ;;
  osx_arm64)
    [[ -z "${OPENSSL_ROOT}" ]] && OPENSSL_ROOT="$(brew --prefix openssl@1.1)"
    EXTRA_PERL_CXXFLAGS="-I$(perl -MConfig -e 'print $Config{archlib}')/CORE"
    LDFLAGS="-L$(brew --prefix readline)/lib"
    CPPFLAGS="-I$(brew --prefix readline)/include"
    PKG_CONFIG_PATH="$(brew --prefix readline)/lib/pkgconfig"
    export LDFLAGS CPPFLAGS PKG_CONFIG_PATH
  ;;
esac
export CXXFLAGS="$CXXFLAGS -I$XROOTD_ROOT/include -I$XROOTD_ROOT/include/xrootd/private \
                 ${UUID_ROOT:+-I$UUID_ROOT/include -L$UUID_ROOT/lib}                    \
                 ${OPENSSL_ROOT:+-I$OPENSSL_ROOT/include -L$OPENSSL_ROOT/lib}           \
                 $EXTRA_PERL_CXXFLAGS"
./configure --prefix="${INSTALLROOT}"                \
            --with-xrootd-location="${XROOTD_ROOT}"  \
            --enable-perl-module                 \
            --with-perl=perl                     \
            --with-swig-inc="${SWIG_LIB}"        \
            --enable-build-server
# May not work in multicore
make
make install INSTALLSITEARCH="${INSTALLROOT}/lib/perl" \
             INSTALLARCHLIB="${INSTALLROOT}/lib/perl"

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
setenv GSHELL_ROOT \$XALIENFS_ROOT
setenv GSHELL_NO_GCC 1
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
