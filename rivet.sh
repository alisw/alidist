package: Rivet
version: "2.2.1"
requires:
  - GSL
  - YODA
  - fastjet
  - HepMC
  - boost
  - CGAL
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
ModuleDir="${INSTALLROOT}/etc/Modules/modulefiles/${PKGNAME}"
mkdir -p "$ModuleDir"
cat > "${ModuleDir}/${PKGVERSION}-${PKGREVISION}" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "Module for loading $PKGNAME $PKGVERSION-$PKGREVISION for the ALICE environment"
}
set version $PKGVERSION-$PKGREVISION
module-whatis "Module for loading $PKGNAME $PKGVERSION-$PKGREVISION for the ALICE environment"
# Dependencies
module load BASE/1.0 YODA/$YODA_VERSION-$YODA_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION GSL/$GSL_VERSION-$GSL_REVISION HepMC/v2.06.09
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv YODA_BASEDIR \$prefix
} else {
  setenv YODA_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(YODA_BASEDIR)/lib
prepend-path PATH \$::env(YODA_BASEDIR)/bin
set pythonpath [exec rivet-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
