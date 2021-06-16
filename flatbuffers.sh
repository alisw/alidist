package: flatbuffers
version: v1.12.0
source: https://github.com/google/flatbuffers
requires:
  - zlib
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  which flatc && printf "#include \"flatbuffers/flatbuffers.h\"\nint main(){}" | c++ -I$(brew --prefix flatbuffers)/include -xc++ -std=c++11 - -o /dev/null
---
cmake $SOURCEDIR                          \
      -G "Unix Makefiles"                 \
      -DFLATBUFFERS_BUILD_TESTS=OFF       \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j $JOBS}
make install

# Work around potentially faulty CMake (missing `install` for binaries)
mkdir -p $INSTALLROOT/bin
for BIN in flathash flatc; do
  [[ -e $INSTALLROOT/bin/$BIN ]] || cp -p $BIN $INSTALLROOT/bin/
done

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEDIR/$PKGNAME"
