package: flatbuffers
version: v1.12.0
source: https://github.com/google/flatbuffers
requires:
  - zlib
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
---
cmake $SOURCEDIR                          \
      -G "Unix Makefiles"                 \
      -DFLATBUFFERS_BUILD_TESTS=OFF       \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-error=unknown-warning-option,unused-but-set-variable"

make ${JOBS:+-j $JOBS}
make install

# Work around potentially faulty CMake (missing `install` for binaries)
mkdir -p $INSTALLROOT/bin
for BIN in flathash flatc; do
  [[ -e $INSTALLROOT/bin/$BIN ]] || cp -p $BIN $INSTALLROOT/bin/
done

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
module load BASE/1.0 ${ZLIB_REVISION:+zlib/${ZLIB_VERSION}-${ZLIB_REVISION}}
# Our environment
set FLATBUFFERS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$FLATBUFFERS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$FLATBUFFERS_ROOT/lib
prepend-path PATH \$FLATBUFFERS_ROOT/bin
EoF
