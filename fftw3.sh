package: FFTW3
version: "%(tag_basename)s"
tag: v3.3.9
source: https://github.com/alisw/fftw3
prefer_system: (?!slc5.*)
requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

cmake $SOURCEDIR                                   \
      -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}" \
      -DCMAKE_INSTALL_LIBDIR:PATH="lib"            \
      -DENABLE_FLOAT=ON                            \
      -DENABLE_AVX=ON                              \
      -DENABLE_AVX2=ON
make ${JOBS+-j $JOBS}
make install

#Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
