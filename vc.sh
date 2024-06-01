package: Vc
version: "%(tag_basename)s"
tag: 1.4.1
source: https://github.com/VcDevel/Vc.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$VC_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DBUILD_TESTING=OFF

make ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --cmake > $MODULEFILE
cat >> "$MODULEFILE" <<EoF		
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include		
EoF
