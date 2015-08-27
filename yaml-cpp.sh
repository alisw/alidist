package: yaml-cpp
version: release-0.5.2
source: https://github.com/jbeder/yaml-cpp
tag: release-0.5.2
requires:
  - boost
---
#!/bin/sh
if [[ $ARCHITECTURE =~ "slc5.*" ]]; then
    sed -i -e 's/-Wno-c99-extensions //' $SOURCEDIR/test/CMakeLists.txt
fi

cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DBUILD_SHARED_LIBS=YES \
  -DBOOST_ROOT:PATH=${BOOST_ROOT} \
  -DCMAKE_SKIP_RPATH=YES \
  -DSKIP_INSTALL_FILES=1

make ${JOBS+-j $JOBS}
make install
