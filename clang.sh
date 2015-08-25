package: Clang
version: "3.6"
source: https://github.com/alisw/clang
tag: master
incremental_recipe: make ${JOBS+-j $JOBS} && make install
---
#!/bin/sh
cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"
  
make ${JOBS+-j $JOBS}
make install
