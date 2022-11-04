package: protobuf
version: v21.9
source: https://github.com/protocolbuffers/protobuf
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
---

cmake $SOURCEDIR/cmake                  \
    -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
    -Dprotobuf_BUILD_TESTS=NO           \
    -Dprotobuf_MODULE_COMPATIBLE=YES    \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF    \
    -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j $JOBS}
make install

#ModuleFile
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
set PROTOBUF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PROTOBUF_ROOT \$PROTOBUF_ROOT
prepend-path LD_LIBRARY_PATH \$PROTOBUF_ROOT/lib
prepend-path PATH \$PROTOBUF_ROOT/bin
EoF
