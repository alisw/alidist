package: MessagePack
version: cpp-2.1.5
tag: cpp-2.1.5
source: https://github.com/msgpack/msgpack-c.git
build_requires:
  - CMake
  - GCC-Toolchain:(?!osx)
  - googletest
---
#!/bin/bash
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}" \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                    \
      -DMSGPACK_CXX11=ON                                      \
      -DGTEST_DIR=$GOOGLETEST_ROOT                            \
      -DGTEST_ROOT=$GOOGLETEST_ROOT                           

make ${JOBS+-j $JOBS}
make test
make install

# Modulefile support
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
setenv MESSAGEPACK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MSGPACK_ROOT \$::env(MESSAGEPACK_ROOT)
prepend-path LD_LIBRARY_PATH \$::env(MESSAGEPACK_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MESSAGEPACK_ROOT)/lib")
prepend-path PATH \$::env(MESSAGEPACK_ROOT)/bin
EoF
