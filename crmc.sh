package: CRMC
version: "%(tag_basename)s-correctHepMC"
tag: v1.7.0
source: https://github.com/alisw/crmc.git
requires:
  - boost
  - HepMC
build_requires:
  - CMake
---
#!/bin/bash -ex
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    LINKER_FLAGS="-Wl,-undefined dynamic_lookup"
  ;;
esac

rsync -a "$SOURCEDIR/" ./

# fix the CMakeFile (taking out fpe treatment which does not compile on AARCH)
sed -i -e 's/src\/CRMCtrapfpe.c//' CMakeLists.txt

cmake ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DCMAKE_Fortran_FLAGS="-std=legacy" \
      ${LINKER_FLAGS:+-DCMAKE_SHARED_LINKER_FLAGS="$LINKER_FLAGS"}
make ${JOBS+-j $JOBS} all
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
module load BASE/1.0 ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} HepMC/$HEPMC_VERSION-$HEPMC_REVISION
# Our environment
set CRMC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv CRMC_ROOT \$CRMC_ROOT
prepend-path PATH \$CRMC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CRMC_ROOT/lib
EoF
