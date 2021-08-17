package: VecGeom
version: "%(tag_basename)s"
tag: 89a05d148cc708d4efc2e7b0eb6e2118d2610057
source: https://gitlab.cern.ch/VecGeom/VecGeom.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Vc"
  - ROOT
build_requires:
  - CMake
---

#!/bin/bash -e

case $ARCHITECTURE in
    osx_arm64)
	cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DROOT=ON  \
	      -DCMAKE_APPLE_SILICON_PROCESSOR=arm64                     \
	      -DBACKEND=Scalar                                          \
	      -DBENCHMARK=ON                                            \
	      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
	      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	;;
    *)
	cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DROOT=ON  \
	      -DBACKEND=Vc                                              \
	      -DVECGEOM_VECTOR=sse4.2                                   \
	      -DBENCHMARK=ON                                            \
	      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
	      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	;;
esac

make ${JOBS+-j $JOBS}
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
module load BASE/1.0 Vc/$VC_VERSION-$VC_REVISION ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set osname [uname sysname]
set VC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv VC_ROOT \$VC_ROOT
prepend-path PATH \$VC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$VC_ROOT/lib
EoF
