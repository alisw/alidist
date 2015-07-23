package: O2
version: master
requires:
  - FairRoot
source: https://github.com/AliceO2Group/AliceO2
tag: master
---
#!/bin/sh
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DFAIRROOTPATH=$FAIRROOT_ROOT \
      -DCMAKE_SKIP_RPATH=TRUE

if [[ $GIT_TAG == master ]]; then
  CONTINUE_ON_ERROR=true
fi
make ${CONTINUE_ON_ERROR+-k} ${JOBS+-j $JOBS}
make install
