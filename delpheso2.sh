package: DelphesO2
version: "%(tag_basename)s"
tag: master
requires:
  - ROOT
  - Delphes
  - O2
  - O2Physics
build_requires:
  - alibuild-recipe-tools
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/AliceO2Group/DelphesO2.git
---
#!/bin/bash -ex
cmake "$SOURCEDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"     \
                   -DCMAKE_INSTALL_LIBDIR=lib                \
                   ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                   -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"    \
                   -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install

#ModuleFile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"

cat << EOF >> "$INSTALLROOT/etc/modulefiles/$PKGNAME"
setenv DELPHESO2_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
