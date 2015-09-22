package: Rivet
version: "2.2.1"
requires:
  - GSL
  - YODA
  - fastjet
  - HepMC
  - boost
---
#!/bin/bash -e
Url="http://www.hepforge.org/archive/rivet/Rivet-${PKGVERSION}.tar.bz2"

curl -Lo rivet.tar.bz2 "$Url"
tar xjf rivet.tar.bz2
cd Rivet-$PKGVERSION
export LDFLAGS="-L${CGAL_ROOT}/lib -L${BOOST_ROOT}/lib ${LDFLAGS}"
export LD_LIBRARY_PATH="${CGAL_ROOT}/lib:${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${LD_LIBRARY_PATH}"
export CXXFLAGS="-Wl,--no-as-needed -lgmp -L${BOOST_ROOT}/lib -lboost_thread -lboost_system -L${CGAL_ROOT}/lib -lCGAL -I${BOOST_ROOT}/include -I${CGAL_ROOT}/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"
./configure \
  --prefix="$INSTALLROOT" \
  --disable-doxygen \
  --with-yoda="$YODA_ROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-hepmc="$HEPMC_ROOT" \
  --with-fastjet="$FASTJET_ROOT" \
  --with-boost="$BOOST_ROOT"
make -j$JOBS
make install -j$JOBS

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
module load BASE/1.0 GSL/$GSL_VERSION-$GSL_REVISION YODA/$YODA_VERSION-$YODA_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION boost/$BOOST_VERSION-$BOOST_REVISION
# Our environment
setenv RIVET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(RIVET_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(RIVET_ROOT)/lib
EoF
