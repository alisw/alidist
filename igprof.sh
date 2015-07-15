package: igprof
version: master
source: https://github.com/igprof/igprof
tag: master
requires:
  - libunwind
---
#!/bin/sh

cmake $SOURCEDIR \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DUNWIND_INCLUDE_DIR=$LIBUNWIND_ROOT/include \
      -DUNWIND_LIBRARY=$LIBUNWIND_ROOT/lib/libunwind.so \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-g -O3"
make ${JOBS+-j $JOBS}
make install
