package: RapidJSON
version: v1.1.0-alice2
tag: 091de040edb3355dcf2f4a18c425aec51b906f08
source: https://github.com/Tencent/rapidjson.git
build_requires:
  - CMake
---
#!/bin/sh

case $ARCHITECTURE in
    osx_arm64)
	cmake $SOURCEDIR                                                       \
	      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                              \
	      -DCMAKE_POLICY_DEFAULT_CMP0077=NEW                               \
	      -DRAPIDJSON_BUILD_TESTS=OFF                                      \
	      -DRAPIDJSON_BUILD_EXAMPLES=OFF
	;;
    *)
	cmake $SOURCEDIR                                                       \
	      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     
	;;
esac

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
EoF
