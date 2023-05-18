package: AliRoot-csa
version: "%(short_hash)s"
tag: master
requires:
  - ROOT
  - SAS
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot
---
#!/bin/sh
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_C_COMPILER=`which ccc-analyzer` \
      -DCMAKE_CXX_COMPILER=`which c++-analyzer`\
      -DCMAKE_Fortran_COMPILER=`which gfortran` \
      -DROOTSYS=$ROOT_ROOT \
      -DALIEN=$ALIEN_ROOT/alien \
      -DOCDB_INSTALL=PLACEHOLDER

case $ARCHITECTURE in 
  osx*) SONAME=dylib ;;
esac

scan-build -load-plugin $SAS_ROOT/lib/libSas.${SONAME:-so} \
           -enable-checker sas.Performance \
           -enable-checker sas.CodingConventions.General \
           -enable-checker core \
           -enable-checker cplusplus \
           -enable-checker unix \
           -o MyReportDir \
           make -k ${JOBS+-j $JOBS} || true
