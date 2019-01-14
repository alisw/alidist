package: AliTPCCommon
version: "%(tag_basename)s"
tag: alitpccommon-v2.3.2.1
source: https://github.com/AliceO2Group/AliTPCCommon
build_requires:
  - CMake
---
#!/bin/bash -e
cmake ${SOURCEDIR}/                         \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE  \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}

make ${JOBS+-j$JOBS}
make install

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
setenv ALITPCCOMMON_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
