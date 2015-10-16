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
cmake "$SOURCEDIR" \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DALIEN="$ALIEN_RUNTIME_ROOT" \
      -DROOTSYS="$ROOT_ROOT" \
      -DFASTJET="$FASTJET_ROOT" \
      -DCGAL="$CGAL_ROOT" \
      -DMPFR="$MPFR_ROOT" \
      -DGMP="$GMP_ROOT" \
      -DALIROOT="$ALIROOT_ROOT"

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} || true
  make -k ${JOBS+-j $JOBS} install || true
else
  make ${JOBS+-j $JOBS}
  make ${JOBS+-j $JOBS} install
fi

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
module load BASE/1.0 AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION
# Our environment
setenv ALIPHYSICS_VERSION \$version
setenv ALIPHYSICS_RELEASE \$::env(ALIPHYSICS_VERSION)
setenv ALICE_PHYSICS \$::env(BASEDIR)/$PKGNAME/\$::env(ALIPHYSICS_RELEASE)
prepend-path PATH \$::env(ALICE_PHYSICS)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALICE_PHYSICS)/lib
EoF
