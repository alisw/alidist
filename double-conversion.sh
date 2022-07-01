package: double-conversion
version: v3.1.5
source: https://github.com/google/double-conversion
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---

mkdir -p $INSTALLROOT

# Downloaded by CMake, built, and linked statically (not needed at runtime):
#   zlib, lz4, brotli
#
# Taken from our stack, linked statically (not needed at runtime):
#   flatbuffers
#
# Taken from our stack, linked dynamically (needed at runtime):
#   boost

cmake $SOURCEDIR                          \
      -DBUILD_TESTING=OFF                 \
      -DBUILD_SHARED_LIBS=OFF             \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS:+-j $JOBS} install

# Trivial module file to keep the linter happy.
# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
EoF
