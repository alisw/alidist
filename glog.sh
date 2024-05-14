package: glog
version: v0.4.0
source: https://github.com/google/glog
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -av --delete --exclude='**/.git' "$SOURCEDIR/" .
autoreconf -ivf
./configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install

#ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
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
set GLOG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GLOG_ROOT \$GLOG_ROOT
prepend-path LD_LIBRARY_PATH \$GLOG_ROOT/lib
prepend-path PATH \$GLOG_ROOT/bin
EoF
