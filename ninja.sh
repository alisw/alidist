package: ninja
version: "fortran-%(short_hash)s"
tag: "5cf291ec1439edffa3c93dde56128181bd5f4037"
source: https://github.com/Kitware/ninja
build_requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

$SOURCEDIR/configure.py --bootstrap
mkdir -p $INSTALLROOT/bin
cp ./ninja $INSTALLROOT/bin

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
set NINJA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv NINJA_ROOT \$NINJA_ROOT
prepend-path PATH \$NINJA_ROOT/bin
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
