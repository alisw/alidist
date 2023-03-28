package: CLHEP
version: "2.2.0.8"
tag: CLHEP_2_2_0_8
source: https://github.com/alisw/clhep
build_requires:
  - CMake
---
#!/bin/sh
cmake $SOURCEDIR \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" <<EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
