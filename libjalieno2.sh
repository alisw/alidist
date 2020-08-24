package: libjalienO2
version: "%(tag_basename)s"
tag: "0.1.2"
source: https://gitlab.cern.ch/jalien/libjalieno2.git
requires:
  - "OpenSSL:(?!osx)"
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - AliEn-Runtime:(?!.*ppc64)
---
#!/bin/bash -e

if [[ $ARCHITECTURE = osx* ]]; then
  OPENSSL_ROOT=$(brew --prefix openssl)
fi

rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR

cmake $BUILDDIR                                                    \
      -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT                             \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
make ${JOBS:+-j $JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}  \\
                     ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}

# Our environment
set LIBJALIENO2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$LIBJALIENO2_ROOT/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
