package: AliPhysics
version: "%(commit_hash)s%(defaults_upper)s"
requires:
  - AliRoot
source: http://git.cern.ch/pub/AliPhysics
write_repo: https://git.cern.ch/reps/AliPhysics
tag: master
env:
  ALICE_PHYSICS: "$ALIPHYSICS_ROOT"
incremental_recipe: make ${JOBS:+-j$JOBS} install
---
#!/bin/bash -e
cmake "$SOURCEDIR" \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DROOTSYS="$ROOT_ROOT" \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"} \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"} \
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"} \
      ${CGAL_ROOT:+-DCGAL="$CGAL_ROOT"} \
      ${MPFR_ROOT:+-DMPFR="$MPFR_ROOT"} \
      ${GMP_ROOT:+-DGMP="$GMP_ROOT"} \
      -DALIROOT="$ALIROOT_ROOT"

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} install || true
  ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS} || true
else
  make ${JOBS+-j $JOBS} install
  if [[ $(ctest -N -R load_library | grep -i "total tests:" | cut -d: -f2) -gt 0 ]]; then
    # Run library loading test if we have them
    ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
  fi
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
