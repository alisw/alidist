package: aurora
version: alice1
source: https://github.com/alisw/aurora
tag: alice/0.16.0
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ ./
./pants binary src/main/python/apache/aurora/client:aurora
mkdir -p $INSTALLROOT/bin
cp dist/aurora.pex $INSTALLROOT/bin/aurora
cp dist/aurora_admin.pex $INSTALLROOT/bin/aurora_admin

# Modulefile
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
setenv AURORA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(AURORA_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(AURORA_ROOT)/lib
prepend-path PERL5LIB $::env(AURORA_ROOT)/lib/perl5
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(AURORA_ROOT)/lib")
EoF
