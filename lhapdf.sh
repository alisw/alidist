package: LHAPDF
version: v6.1.5
source: https://github.com/alisw/LHAPDF
tag: v6.1.5
requires:
 - yaml-cpp
 - boost
 - autotools
---
#!/bin/sh
# Does not work out of source.

rsync -a $SOURCEDIR/ ./

# autoreconf if using our own build of autotools
[[ -n ${AUTOTOOLS_ROOT} ]] && autoreconf -ivf

case $PKGVERSION in
    v6.0*) WITH_YAML_CPP="--with-yaml-cpp=${YAML_CPP_ROOT}"
esac

./configure --prefix=$INSTALLROOT \
            --with-boost=${BOOST_ROOT} \
            $WITH_YAML_CPP

make ${JOBS+-j $JOBS} all
make install
