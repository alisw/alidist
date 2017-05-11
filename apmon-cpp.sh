package: ApMon-CPP
version: "%(tag_basename)s"
tag: v2.2.8
source: https://github.com/alisw/apmon-cpp.git
build_requires:
 - autotools
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
autoreconf -ivf
./configure --prefix=$INSTALLROOT
make ${JOBS:+-j$JOBS}
make install

# Modules
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
module load BASE/1.0 \\
       ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv APMON_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(APMON_ROOT)/bin
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
