package: AEGIS
version: "%(tag_basename)s"
tag: v1.5.9
requires:
  - ROOT
  - VMC
  - pythia6
  - nlohmann_json
build_requires:
  - CMake
  - hijing
  - "Xcode:(osx.*)"
  - ninja-fortran
  - alibuild-recipe-tools
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
                 -G "Ninja"                                \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE                   \
                 -DPYTHIA6_DIR=${PYTHIA6_ROOT}             \
                 -DCMAKE_C_STANDARD=99                     \
                 ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch"}
cmake --build . -- ${JOBS:+-j$JOBS} install

# Add an extra RPATH for the local libraries on macOS
case ${ARCHITECTURE} in
  osx*)
    install_name_tool -add_rpath $INSTALLROOT/lib $INSTALLROOT/lib/libTEPEMGEN.dylib
    install_name_tool -add_rpath $PYTHIA6_ROOT/lib $INSTALLROOT/lib/libTEPEMGEN.dylib
    ;;
esac

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --root > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
setenv AEGIS_ROOT \$PKG_ROOT
EoF
