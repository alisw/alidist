package: RooUnfold
version: "%(tag_basename)s"
tag: V02-00-01-alice4
source: https://github.com/alisw/RooUnfold
requires:
 - ROOT
 - boost
---
cmake $SOURCEDIR                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD} \
      -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j$JOBS} install
#make test

rsync -av $SOURCEDIR/include/ $INSTALLROOT/include/
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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv ROOUNFOLD_RELEASE \$version
setenv ROOUNFOLD_VERSION $PKGVERSION
set ROOUNFOLD_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ROOUNFOLD_RELEASE)
setenv ROOUNFOLD_ROOT \$ROOUNFOLD_ROOT
prepend-path PATH \$ROOUNFOLD_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ROOUNFOLD_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$ROOUNFOLD_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
