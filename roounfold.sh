package: RooUnfold
version: "%(tag_basename)s%(defaults_upper)s"
tag: alice/V02-00-01
source: https://github.com/alisw/RooUnfold
requires:
 - ROOT
 - boost
---
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j$JOBS} install
make test

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv ROOUNFOLD_RELEASE \$version
setenv ROOUNFOLD_VERSION $PKGVERSION
setenv ROOUNFOLD_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ROOUNFOLD_RELEASE)
prepend-path PATH \$::env(ROOUNFOLD_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ROOUNFOLD_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ROOUNFOLD_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
