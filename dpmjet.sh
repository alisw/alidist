package: DPMJET
version: "%(tag_basename)s"
tag: "v19.1.2-alice1"
source: https://github.com/alisw/DPMJET.git
requires:
 - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - "Xcode:(osx.*)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
FVERSION=`gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1`
SPECIALFFLAGS=""
if [ $FVERSION -ge 10 ]; then
   echo "Fortran version $FVERSION"
   SPECIALFFLAGS=1
fi

cmake  $SOURCEDIR                           \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
       ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch"}

make ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env > "$MODULEDIR/$PKGNAME"
