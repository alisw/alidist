package: RapidJSON
version: "%(tag_basename)s"
tag: 091de040edb3355dcf2f4a18c425aec51b906f08
source: https://github.com/Tencent/rapidjson.git
build_requires:
  - CMake
---
#!/bin/sh

cmake $SOURCEDIR                                                       \
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
setenv RAPID_JSON_HOME \$::env(BASEDIR)/$PKGNAME/\$version 
prepend-path PATH \$::env(RAPID_JSON_HOME)/bin
prepend-path LD_LIBRARY_PATH \$::env(RAPID_JSON_HOME)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(RAPID_JSON_HOME)/lib")
EoF
