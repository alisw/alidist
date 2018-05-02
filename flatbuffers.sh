package: flatbuffers
version: v1.8.0
source: https://github.com/google/flatbuffers
requires:
  - zlib
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include \"flatbuffers/flatbuffers.h\"\nint main(){}" | c++ -I$(brew --prefix flatbuffers)/include -xc++ -std=c++11 - -o /dev/null
---
cmake $SOURCEDIR                          \
      -G "Unix Makefiles"                 \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j $JOBS}
make install

# Work around potentially faulty CMake (missing `install` for binaries)
mkdir -p $INSTALLROOT/bin
for BIN in flathash flatc flatsamplebinary flatsampletext flattests; do
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
module load BASE/1.0 ${ZLIB_VERSION:+zlib/${ZLIB_VERSION}-${ZLIB_REVISION}}
# Our environment
setenv FLATBUFFERS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(FLATBUFFERS_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(FLATBUFFERS_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FLATBUFFERS_ROOT)/lib")
prepend-path PATH \$::env(FLATBUFFERS_ROOT)/bin
EoF
