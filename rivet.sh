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

# MPFR and GMP are compiled statically, however in some cases there might be
# some "-lgmp" left somewhere and we have to deal with it with the correct path.
# Boost flags are also necessary
export LDFLAGS="-Wl,--no-as-needed -L${MPFR_ROOT}/lib -L${GMP_ROOT}/lib -L${CGAL_ROOT}/lib -lCGAL"
export LIBRARY_PATH="$LD_LIBRARY_PATH"
export CXXFLAGS="-I${MPFR_ROOT}/include -I${GMP_ROOT}/include -I${CGAL_ROOT}/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"

if [[ "$BOOST_ROOT" != '' ]]; then
  export LDFLAGS="$LDFLAGS -L$BOOST_ROOT/lib"
  export CXXFLAGS="-I$BOOST_ROOT/include"
fi
export LDFLAGS="$LDFLAGS -lboost_thread -lboost_system"

./configure \
  --prefix="$INSTALLROOT" \
  --disable-doxygen \
  --with-yoda="$YODA_ROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-hepmc="$HEPMC_ROOT" \
  --with-fastjet="$FASTJET_ROOT" \
  ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"}
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
module load BASE/1.0 GSL/$GSL_VERSION-$GSL_REVISION YODA/$YODA_VERSION-$YODA_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION ${BOOST_ROOT:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv RIVET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(RIVET_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(RIVET_ROOT)/lib
EoF
