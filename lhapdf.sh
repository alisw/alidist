package: LHAPDF
version: v6.1.5
source: https://github.com/alisw/LHAPDF
tag: v6.1.5
requires:
  - yaml-cpp
---
#!/bin/sh
# Does not work out of source.

cd $SOURCEDIR
./configure --prefix=$INSTALLROOT \
            --with-boost=${BOOST_ROOT} \
            --with-yaml-cpp=${YAML_CPP_ROOT}

make ${JOBS+-j $JOBS} all
make install
