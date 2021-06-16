package: double-conversion
version: v3.1.5
source: https://github.com/google/double-conversion
build_requires:
  - CMake
  - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEDIR/$PKGNAME"
