package: Openloops
version: "%(tag_basename)s"
tag: "OpenLoops-2.1.1"
source: https://gitlab.com/openloops/OpenLoops.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
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

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set OPENLOOPS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv OPENLOOPS_ROOT \$OPENLOOPS_ROOT
setenv OpenLoopsPath \$OPENLOOPS_ROOT
prepend-path PATH \$OPENLOOPS_ROOT
prepend-path LD_LIBRARY_PATH \$OPENLOOPS_ROOT/lib
prepend-path LD_LIBRARY_PATH \$OPENLOOPS_ROOT/proclib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

