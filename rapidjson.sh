package: RapidJSON
version: 1.1.0
source: https://github.com/miloyip/rapidjson
build_requires:
  - CMake
tag: v1.1.0
---
#!/bin/sh

GCC_VERSION_MAJOR=$(gcc --version | awk 'NR==1 {print $3}' | cut -d '.' -f1)
if [ "$GCC_VERSION_MAJOR" -ge "7" ]; then
  NO_ERROR_FALLTHROUGH="-Wno-error=implicit-fallthrough"
fi

cmake $SOURCEDIR                                                       \
      ${NO_ERROR_FALLTHROUGH:+-DCMAKE_CXX_FLAGS=$NO_ERROR_FALLTHROUGH} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     

make ${JOBS:+-j$JOBS} install

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
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
