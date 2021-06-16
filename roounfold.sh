package: RooUnfold
version: "%(tag_basename)s"
tag: V02-00-01-alice5
source: https://github.com/alisw/RooUnfold
requires:
 - ROOT
 - boost
build_requires:
 - alibuild-recipe-tools
---
cmake $SOURCEDIR                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT     \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD} \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"}    \
      -DROOT_DIR=$ROOT_ROOT \
      -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j$JOBS} install
#make test

rsync -av $SOURCEDIR/include/ $INSTALLROOT/include/
# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --extra > "etc/modulefiles/$PKGNAME" <<EoF
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
