package: AEGIS
version: "%(tag_basename)s"
tag: v1.5.3-alice2
requires:
  - ROOT
  - VMC
  - pythia6
build_requires:
  - CMake
  - hijing
  - "Xcode:(osx.*)"
source: https://github.com/AliceO2Group/AEGIS.git
prepend_path:
  LD_LIBRARY_PATH: "$AEGIS_ROOT/lib"
  ROOT_INCLUDE_PATH: "$AEGIS_ROOT/include"
---
#!/bin/bash -e
FVERSION=`gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1`
SPECIALFFLAGS=""
if [ $FVERSION -ge 10 ]; then
   echo "Fortran version $FVERSION"
   SPECIALFFLAGS=1
fi
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE                   \
                 -DPYTHIA6_DIR=${PYTHIA6_ROOT}             \
		 ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch"}
cmake --build . -- ${JOBS:+-j$JOBS} install

# Add an extra RPATH for the local libraries on macOS

case ${ARCHITECTURE} in
  osx*)
    install_name_tool -add_rpath $INSTALLROOT/lib $INSTALLROOT/lib/libTEPEMGEN.dylib
    ;;
esac

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION 
# Our environment
set AEGIS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv AEGIS_ROOT \$AEGIS_ROOT
prepend-path LD_LIBRARY_PATH \$AEGIS_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$AEGIS_ROOT/include
EoF
