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
else
  make ${JOBS+-j $JOBS}
fi

# "make install" does not work well: copy by hand
# Imported from the legacy maketarball.sh
for D in $BUILDDIR $SOURCEDIR; do
  rsync -av --cvs-exclude \
        --exclude='tgt_*' \
        --exclude='CMakeFiles' \
        --exclude='**/OCDB/*' \
        --exclude='**/data/maps/*' \
        --exclude='**/data/field*.dat' \
        --exclude='**/data/cp*.dat' \
        --exclude='**/EMCAL/ShuttleInput' \
        --exclude='*/Ref' \
        --exclude='*.cxx' \
        --exclude='*.F' \
        --exclude='*.f' \
        --exclude='G__*' \
        --exclude='**/TPC/Cov*.root' \
        --exclude='**/doc' \
        --exclude='**/picts' \
        --exclude='**/ITS/oldmacros' \
        --exclude='**/ITS/ITSlegov5.map' \
        --exclude='**/LHAPDF/PDFsets/*' \
        $D/ $INSTALLROOT/
done
rsync -av $BUILDDIR/bin/ $INSTALLROOT/bin/
rsync -av $BUILDDIR/lib/ $INSTALLROOT/lib/
cp -pv $SOURCEDIR/data/maps/mfchebKGI_sym.root \
       $INSTALLROOT/data/maps/
cp -pv $SOURCEDIR/LHAPDF/PDFsets/{EPS09LOR_197,EPS09LOR_208,EPS09NLOR_197,EPS09NLOR_208,cteq4l,cteq4m,cteq5l,cteq5m,GRV98lo}.LHgrid \
       $SOURCEDIR/LHAPDF/PDFsets/{cteq6,cteq61,cteq6m,cteq6l,cteq6ll}.LHpdf \
       $INSTALLROOT/LHAPDF/PDFsets/

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION
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
