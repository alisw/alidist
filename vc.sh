package: Vc
version: "%(tag_basename)s"
tag: 1.4.5
source: https://github.com/VcDevel/Vc.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
prepend_path:
  ROOT_INCLUDE_PATH: "$VC_ROOT/include"
---
#!/bin/bash -e
cmake $SOURCEDIR -G Ninja -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DBUILD_TESTING=OFF

cmake --build . --target install ${JOBS+-j $JOBS}

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --cmake > $MODULEFILE
cat >> "$MODULEFILE" <<EoF		
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include		
EoF
