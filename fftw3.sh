package: FFTW3
version: "%(tag_basename)s"
tag: v3.3.9
source: https://github.com/alisw/fftw3
prefer_system: (?!slc5.*)
build_requires:
  - alibuild-recipe-tools
  - CMake
---
#!/bin/bash -e
export FFTW3_WITH_AVX # use AVX with float or double. Unset automatically for long double and quad

if [[ $FFTW3_DOUBLE == "ON" ]]; then # ensure only one option is set and AVX is disabled if necessary
  FFTW3_FLOAT="OFF"
  FFTW3_LONG_DOUBLE="OFF"
elif [[ $FFTW3_LONG_DOUBLE == "ON" ]]; then
  unset FFTW3_WITH_AVX
  FFTW3_FLOAT="OFF"
  FFTW3_DOUBLE="OFF"
else # keep FLOAT default option as it was
  FFTW3_FLOAT="ON"
  FFTW3_DOUBLE="OFF"
  FFTW3_LONG_DOUBLE="OFF"
fi

case $ARCHITECTURE in
    osx_arm64)
  cmake $SOURCEDIR                                          \
        -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}"        \
        -DCMAKE_INSTALL_LIBDIR:PATH="lib"                   \
        -DENABLE_LONG_DOUBLE=${FFTW3_LONG_DOUBLE-OFF}       \
        -DENABLE_FLOAT=${FFTW3_FLOAT-OFF}
  ;;
    *)
  cmake $SOURCEDIR                                          \
        -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}"        \
        -DCMAKE_INSTALL_LIBDIR:PATH="lib"                   \
        -DENABLE_LONG_DOUBLE=${FFTW3_LONG_DOUBLE-OFF}       \
        -DENABLE_FLOAT=${FFTW3_FLOAT-OFF}                   \
        ${FFTW3_WITH_AVX:+-DENABLE_AVX=ON}
  ;;
esac

make ${JOBS+-j $JOBS}
make install

#Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
