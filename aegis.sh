package: AEGIS
version: "%(tag_basename)s"
tag: v1.4
requires:
  - ROOT
  - pythia6
build_requires:
  - CMake
  - hijing
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/AEGIS.git
prepend_path:
  LD_LIBRARY_PATH: "$AEGIS_ROOT/lib"
  ROOT_INCLUDE_PATH: "$AEGIS_ROOT/include"
---
#!/bin/bash -e
FVERSION=`gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1`
SPECIALFFLAGS=""
if [ $FVERSION -ge 10 ]; then
   echo "Fortran version $FVERSION"
   SPECIALFFLAGS=1
fi
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE \
		 ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch"}
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root-env > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
EoF
