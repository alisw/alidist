package: GEANT3
version: "%(commit_hash)s-0"
tag: v1-15a
requires:
  - ROOT
  - CMake
source: http://root.cern.ch/git/geant3.git
prepend_path:
  "LD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
  "DYLD_LIBRARY_PATH": "$GEANT3_ROOT/lib64"
---
#!/bin/bash -e
ROOTARCH=$(root-config --arch)
rsync -a --cvs-exclude --delete $SOURCEDIR/ $BUILDDIR/
make ${JOBS+-j$JOBS}
# GEANT3 < 2.0 does not have "make install"
mkdir $INSTALLROOT/{TGeant3,lib}
cp -v $BUILDDIR/TGeant3/*.h $INSTALLROOT/TGeant3/
rsync -av $BUILDDIR/lib/tgt_$ROOTARCH/ $INSTALLROOT/lib/tgt_$ROOTARCH/

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION CMake/$CMAKE_VERSION-$CMAKE_REVISION
# Our environment
setenv GEANT3_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GEANT3DIR \$::env(GEANT3_ROOT)
prepend-path LD_LIBRARY_PATH \$::env(GEANT3_ROOT)/lib/tgt_$ROOTARCH
EoF
