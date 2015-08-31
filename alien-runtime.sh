package: AliEn-Runtime
version: v2-19-xrd2
source: https://gitlab.cern.ch/dberzano/AliEn-antidot.git
prepend_path:
  LD_LIBRARY_PATH: "$ALIEN_RUNTIME_ROOT/api/lib"
  DYLD_LIBRARY_PATH: "$ALIEN_RUNTIME_ROOT/api/lib"
  PATH: "$ALIEN_RUNTIME_ROOT/api/bin"
env:
  GSHELL_ROOT: "$ALIEN_RUNTIME_ROOT/api"
  GSHELL_NO_GCC: "1"
---
#!/bin/bash -e
rsync -a --cvs-exclude $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR
./bootstrap
./configure --prefix=$INSTALLROOT

pushd meta/user
make install
popd

chmod u+w -R $INSTALLROOT/

# Remove docs: unneeded, save lots of space
pushd $INSTALLROOT
rm -rf docs man api/share/man share/man share/doc
popd

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
setenv ALIEN_RUNTIME_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ALIEN_RUNTIME_BASEDIR)/lib
prepend-path LD_LIBRARY_PATH \$::env(ALIEN_RUNTIME_BASEDIR)/api/lib
prepend-path PATH \$::env(ALIEN_RUNTIME_BASEDIR)/bin
prepend-path PATH \$::env(ALIEN_RUNTIME_BASEDIR)/api/bin
setenv GSHELL_ROOT \$::env(ALIEN_RUNTIME_BASEDIR)/api
setenv GSHELL_NO_GCC 1
EoF
