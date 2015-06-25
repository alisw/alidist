package: aliroot
version: v5-06-28
requires:
  - root
source: http://git.cern.ch/pub/AliRoot
tag: master
---
#!/bin/sh

cmake . -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
        -DROOTSYS=$ROOT_ROOT
make -j 20
make install
