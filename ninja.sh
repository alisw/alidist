package: ninja
version: "1.8.2"
tag: "v1.8.2"
source: https://github.com/ninja-build/ninja
build_requires:
 - "GCC-Toolchain:(?!osx)"
prefer_system: .*
prefer_system_check: |
  ninja --version > /dev/null; if test $? = 127; then exit 1; else case `ninja --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in "^(0|2)\.|^1\.([0-7]|[9-99])\.\d*|^1\.8\.[0-1]" ) exit 1 ;; esac; fi; exit 0
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
setenv NINJA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(NINJA_ROOT)/bin
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
