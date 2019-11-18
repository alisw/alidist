package: yacc-like
version: "1.0"
tag: ad9a652456adfe2a554fd2542dd4831575b2be03
source: https://github.com/alisw/yacc-like
prefer_system: .*
prefer_system_check: |
  set -e
  export PATH=$(brew --prefix bison)/bin:$PATH
  which bison
  # We need 2.5 or better
  case `bison --version | head -n 1| sed -e's/.* //'` in
    1.*|2.1*|2.2*|2.3*|2.4*) false ;;
    *) ;;
  esac
  which flex
build_requires:
 - GCC-Toolchain
 - autotools
---
rsync -a --delete --exclude="**/.git" $SOURCEDIR/ ./
pushd bison
  autoreconf -ivf
  ./configure --prefix ${INSTALLROOT} --disable-manpages

  make ${JOBS:+-j $JOBS}
  make install
popd
pushd flex
  autoreconf -ivf
  ./configure --prefix ${INSTALLROOT} --disable-manpages

  make ${JOBS:+-j $JOBS}
  make install
popd

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
module load BASE/1.0
# Our environment
set YACC_LIKE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$YACC_LIKE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$YACC_LIKE_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
