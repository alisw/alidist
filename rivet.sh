package: Rivet
version: "v2.2.1"
requires:
  - GSL
  - YODA
  - fastjet
---
#!/bin/bash -e
VerWithoutV=${PKGVERSION:1}
Url="http://www.hepforge.org/archive/rivet/Rivet-${VerWithoutV}.tar.bz2"

# External dependencies. TODO: build them instead.
Boost="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0"
HepMC="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/HepMC/v2.06.09"
Cgal="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/cgal/v4.4"

curl -Lo rivet.tar.bz2 "$Url"
tar xjf rivet.tar.bz2
cd Rivet-$VerWithoutV
export LDFLAGS="-L$Cgal/lib -L$Boost/lib ${LDFLAGS}"
export LD_LIBRARY_PATH="${Cgal}/lib:${Boost}/lib:${LD_LIBRARY_PATH}"
./configure \
  --prefix="$INSTALLROOT" \
  --disable-doxygen \
  --with-yoda="$YODA_ROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-hepmc="$HepMC" \
  --with-fastjet="$FASTJET_ROOT" \
  --with-boost="$Boost"
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
