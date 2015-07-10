package: root
version: v5-34-30
source: http://github.com/root-mirror/root
tag: v5-34-30
requires: 
  - zlib
  - cmake
  - alien
---
#!/bin/sh -e

cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
                 -Dc++11=ON \
                 -DCMAKE_Fortran_COMPILER=gfortran \
                 -Dpythia6_nolink=ON \
                 -Droofit=ON \
                 -Dminuit2=ON \
                 -Dalien=OFF \
                 -Dxrootd=ON \
                 -Dgsl_shared=ON \
                 -Dglobus=OFF

make ${JOBS+-j $JOBS}
make install
