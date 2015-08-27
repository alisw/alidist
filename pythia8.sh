package: pythia8
version: "v8210"
source: https://github.com/alisw/pythia8
requires:
  - LHAPDF
  - HepMC
  - boost
tag: alice/v8210
---
#!/bin/sh
rsync -a $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT \
            --enable-shared \
            --with-hepmc2=${HEPMC_ROOT} \
            --with-lhapdf6=${LHAPDF_ROOT} \
            --with-boost=${BOOST_ROOT}

if [[ $ARCHITECTURE =~ "slc5.*" ]]; then
    ln -s LHAPDF5.h include/Pythia8Plugins/LHAPDF5.cc
    ln -s LHAPDF6.h include/Pythia8Plugins/LHAPDF6.cc
    sed -i -e 's#\$(CXX) -x c++ \$< -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#\$(CXX) -x c++ \$(<:.h=.cc) -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#' Makefile
fi

make ${JOBS+-j $JOBS}
make install
