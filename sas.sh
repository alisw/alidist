package: SAS
version: "0.1.3"
source: https://github.com/ktf/SAS.git
tag: master
requires:
  - Clang:(?!osx*)
---
#!/bin/sh
cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_DEV_DIR=$CLANG_ROOT
  
make ${JOBS+-j $JOBS}
make install
