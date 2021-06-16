package: ninja
version: "fortran-%(short_hash)s"
tag: "v1.8.2.g3bbbe.kitware.dyndep-1.jobserver-1"
source: https://github.com/Kitware/ninja
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
---
#!/bin/bash -e

$SOURCEDIR/configure.py --bootstrap
mkdir -p $INSTALLROOT/bin
cp ./ninja $INSTALLROOT/bin

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --root-env > "etc/modulefiles/$PKGNAME"
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
