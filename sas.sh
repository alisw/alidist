package: SAS
version: "0.1.3"
tag: master
source: https://github.com/ktf/SAS.git
requires:
  - Clang:(?!osx*)
---
#!/bin/sh
cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT" \
  -DLLVM_DEV_DIR=$CLANG_ROOT
  
make ${JOBS+-j $JOBS}
make install
