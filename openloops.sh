package: Openloops
version: "%(tag_basename)s"
tag: "v2.1.0-alice1"
source: https://github.com/alisw/Openloops
requires:
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ .

unset HTTP_PROXY # unset this to build on slc6 system

./scons 

JOBS=$((${JOBS:-1}*1/5))
[[ $JOBS -gt 0 ]] || JOBS=1

PROCESSES=(ppjj ppjj_ew ppjjj ppjjj_ew ppjjj_nf5 ppjjjj)
for proc in ${PROCESSES[@]}; do
    ./scons --jobs=$JOBS auto="$proc"  
done

INSTALL=(examples include lib openloops proclib pyol)
for inst in ${INSTALL[@]}; do
    cp -r $inst $INSTALLROOT/
done

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
set OPENLOOPS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv OpenLoopsPath \$OPENLOOPS_ROOT
prepend-path PATH \$OPENLOOPS_ROOT
prepend-path LD_LIBRARY_PATH \$OPENLOOPS_ROOT/lib
prepend-path LD_LIBRARY_PATH \$OPENLOOPS_ROOT/proclib
EoF
