package: JETSCAPE
version: "%(tag_basename)s"
tag: "v3.1.1-alice6"
source: https://github.com/alisw/JETSCAPE
requires:
  - boost
  - hdf5
  - pythia
  - HepMC3
  - ROOT
build_requires:
  - CMake
  - "Xcode:(osx.*)"
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $HDF5_ROOT ]] && HDF5_ROOT=`brew --prefix hdf5`
  ;;
esac

  export HEPMC_DIR=$HEPMC3_ROOT
  cmake "$SOURCEDIR"                             \
    -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"        \
    -DPYTHIA8=$PYTHIA_ROOT                       \
    -Dunittests=OFF                              \
    ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# must put some stuff by hands for the time being
cp runJetscape $INSTALLROOT/bin/.
cp -r $SOURCEDIR/config $INSTALLROOT/.

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
module load BASE/1.0 ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${HDF5_REVISION:+hdf5/$HDF5_VERSION-$HDF5_REVISION} ${HEPMC3_REVISION:+HepMC3/$HEPMC3_VERSION-$HEPMC3_REVISION} ${PYTHIA_REVISION:+pythia/$PYTHIA_VERSION-$PYTHIA_REVISION}
# Our environment
set JETSCAPE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv JETSCAPE_ROOT \$JETSCAPE_ROOT
prepend-path PATH \$JETSCAPE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$JETSCAPE_ROOT/lib
EoF
