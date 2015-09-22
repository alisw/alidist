package: AliRoot
version: "%(commit_hash)s"
requires:
  - ROOT
  - fastjet
build_requires:
  - CMake
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot 
tag: master
incremental_recipe: make ${JOBS:+-j$JOBS} && make install && cp -r $SOURCEDIR/test $INSTALLROOT/test
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_RUNTIME_ROOT \
      -DFASTJET=$FASTJET_ROOT \
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
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib
EoF
