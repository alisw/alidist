package: AliPhysics
version: "%(commit_hash)s"
requires:
  - AliRoot
source: http://git.cern.ch/pub/AliPhysics
tag: master
env:
  ALICE_PHYSICS: "$ALIPHYSICS_ROOT"
incremental_recipe: make ${JOBS:+-j$JOBS} && make install
---
#!/bin/bash -e
# TODO: build with -DFASTJET
cmake "$SOURCEDIR" \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DALIEN="$ALIEN_RUNTIME_ROOT" \
      -DROOTSYS="$ROOT_ROOT" \
      -DALIROOT="$ALIROOT_ROOT"
make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/Modules/modulefiles/$PKGNAME"
MODULEFILE="$MODULEDIR/$PKGVERSION-$PKGREVISION"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-$PKGREVISION"
}
set version $PKGVERSION-$PKGREVISION
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-$PKGREVISION"
# Dependencies
module load BASE/1.0 AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION
# Our environment
setenv ALIPHYSICS_VERSION \$version
setenv ALIPHYSICS_RELEASE \$::env(ALIPHYSICS_VERSION)
setenv ALICE_PHYSICS \$::env(BASEDIR)/$PKGNAME/\$::env(ALIPHYSICS_RELEASE)
prepend-path PATH \$::env(ALICE_PHYSICS)/bin
prepend-path  LD_LIBRARY_PATH \$::env(ALICE_PHYSICS)/lib
EoF
