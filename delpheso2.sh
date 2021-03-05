package: DelphesO2
version: "%(tag_basename)s"
tag: master
requires:
  - ROOT
  - Delphes
  - O2
overrides:
  O2:
    version: "%(short_hash)s%(defaults_upper)s"
    tag: dev
build_requires:
  - alibuild-recipe-tools
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/AliceO2Group/DelphesO2.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 -DCMAKE_INSTALL_LIBDIR=lib                \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS} install

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME

cat << EOF >> $INSTALLROOT/etc/modulefiles/$PKGNAME
set DELPHESO2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv DELPHESO2_ROOT \$DELPHESO2_ROOT
prepend-path PATH \$DELPHESO2_ROOT/bin
prepend-path LD_LIBRARY_PATH \$DELPHESO2_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$DELPHESO2_ROOT/include
EOF
