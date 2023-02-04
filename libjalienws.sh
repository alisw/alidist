package: libjalienws
version: "%(tag_basename)s"
tag: "0.1.5"
source: https://gitlab.cern.ch/jalien/libjalienws.git
requires:
  - libjalienO2
  - AliEn-Runtime
build_requires:
  - libwebsockets
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR

cmake $BUILDDIR                                          	\
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
make ${JOBS:+-j $JOBS} VERBOSE=1 install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
                     ${LIBJALIENO2_REVISION:+libjalienO2/$LIBJALIENO2_VERSION-$LIBJALIENO2_REVISION}

# Our environment
set LIBJALIENWS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$LIBJALIENWS_ROOT/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
