package: IgProf
version: 5.9.16
source: https://github.com/igprof/igprof
tag: v5.9.16
requires:
  - libunwind
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/sh

cmake $SOURCEDIR \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DUNWIND_INCLUDE_DIR=$LIBUNWIND_ROOT/include \
      -DUNWIND_LIBRARY=$LIBUNWIND_ROOT/lib/libunwind.so \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-g -O3 -U_FORTIFY_SOURCE -Wno-attributes"
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
