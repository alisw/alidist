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
# ROOT and O2 need different variants of fftw3, but we cannot configure fftw3
# to build both at the same time. As a workaround, configure and build one,
# then wipe out the build directory and configure and build the second one.

# First, build fftw3 (double precision), required by ROOT.
cmake -S "$SOURCEDIR" -B "$BUILDDIR/fftw3"              \
      -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"        \
      -DCMAKE_INSTALL_LIBDIR:PATH=lib
make -C "$BUILDDIR/fftw3" ${JOBS+-j "$JOBS"}
make -C "$BUILDDIR/fftw3" install

# Now reconfigure for fftw3f (single precision float), required by O2.
cmake -S "$SOURCEDIR" -B "$BUILDDIR/fftw3f"             \
      -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"        \
      -DCMAKE_INSTALL_LIBDIR:PATH=lib                   \
      -DENABLE_FLOAT=ON
make -C "$BUILDDIR/fftw3f" ${JOBS+-j "$JOBS"}
make -C "$BUILDDIR/fftw3f" install

#Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
