package: AliRoot
version: "%(commit_hash)s"
requires:
  - ROOT
  - CMake
prepend_path:
  LD_LIBRARY_PATH: "$ALIROOT_ROOT/lib/tgt_$ALICE_TARGET"
  DYLD_LIBRARY_PATH: "$ALIROOT_ROOT/lib/tgt_$ALICE_TARGET"
  PATH: "$ALIROOT_ROOT/bin/tgt_$ALICE_TARGET"
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
  ALICE_TARGET: "$(root-config --arch)"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot 
tag: v5-05-Rev-22-patches
incremental_recipe: make ${JOBS:+-j$JOBS} && make install
---
#!/bin/bash -e

export ALICE=$INSTALLROOT
export ALICE_ROOT=$SOURCEDIR
export ALICE_TARGET=$(root-config --arch)

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_RUNTIME_ROOT \
      ${FASTJET_ROOT:+-DFASTJET=$FASTJET_ROOT} \
      -DOCDB_INSTALL=PLACEHOLDER

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} || true
  make -k install || true
else
  make ${JOBS+-j $JOBS}
  make install
fi
cp -r $SOURCEDIR/test $INSTALLROOT/test

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION
# Our environment
setenv ALIROOT_VERSION \$version
setenv ALICE \$::env(BASEDIR)/$PKGNAME
setenv ALIROOT_RELEASE \$::env(ALIROOT_VERSION)
setenv ALICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIROOT_RELEASE)
prepend-path PATH \$::env(ALICE_ROOT)/bin
prepend-path PATH \$::env(ALICE_ROOT)/bin/tgt_$ALICE_TARGET
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib/tgt_$ALICE_TARGET
EoF
