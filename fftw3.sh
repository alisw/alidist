package: FFTW3
version: "%(tag_basename)s"
tag: v3.3.9
source: https://github.com/alisw/fftw3
prefer_system: (?!slc5.*)
build_requires:
  - alibuild-recipe-tools
  - CMake
  - "GCC-Toolchain:(?!osx)"
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
else
  # Install libfftw3.so by default, not libfftw3{f,l}.so. ROOT only looks for the former.
  FFTW3_FLOAT="OFF"
  FFTW3_DOUBLE="ON"
  FFTW3_LONG_DOUBLE="OFF"
fi

case $ARCHITECTURE in
  osx_arm64) unset FFTW3_WITH_AVX ;;
esac

cmake "$SOURCEDIR"                                        \
      -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}"        \
      -DCMAKE_INSTALL_LIBDIR:PATH="lib"                   \
      -DENABLE_LONG_DOUBLE=${FFTW3_LONG_DOUBLE-OFF}       \
      -DENABLE_FLOAT=${FFTW3_FLOAT-OFF}                   \
      ${FFTW3_WITH_AVX:+-DENABLE_AVX=ON}
make ${JOBS+-j $JOBS}
make install

#Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
