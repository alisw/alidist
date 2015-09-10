package: ThePEG
version: v20150318
source: https://github.com/alisw/thepeg
tag: "alice/v2015-03-18"
requires:
  - Rivet
  - GSL
  - fastjet
  - pythia8
  - HepMC
  - lhapdf5
  - cgal
  - boost
---
#!/bin/bash -e

export LD_LIBRARY_PATH="${LHAPDF5_ROOT}/lib:${CGAL_ROOT}/lib:${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${LHAPDF5_ROOT}/lib:${CGAL_ROOT}/lib:${BOOST_ROOT}/lib:${LIBRARY_PATH}"
export LHAPATH="${LHAPDF5_ROOT}/share/lhapdf"
export PERLLIB=/usr/share/perl5

rsync -a $SOURCEDIR/ ./

sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/Config/interfaces.pl.in
sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.am
sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.in

# not required for Ubuntu but to be checked if needed
# when we can build and test on SLC 5:
#find . \
#  -name configure.ac -or \
#  -name aclocal.m4 -or \
#  -name configure -or \
#  -name Makefile.am -or \
#  -name Makefile.in \
#  -exec touch '{}' \;
#autoreconf -ivf
./configure \
  --disable-silent-rules \
  --enable-shared \
  --disable-static \
  --without-javagui \
  --prefix="$INSTALLROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-pythia8="$PYTHIA8_ROOT" \
  --with-hepmc="$HEPMC_ROOT" \
  --with-rivet="$RIVET_ROOT" \
  --with-lhapdf="$LHAPDF5_ROOT" \
  --with-fastjet="$FASTJET_ROOT" \
  --enable-unitchecks
make -j$JOBS C_INCLUDE_PATH="${GSL_ROOT}/include" CPATH="${GSL_ROOT}/include"
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
module load BASE/1.0 lhapdf5/$LHAPDF5_VERSION-$LHAPDF5_REVISION pythia/$PYTHIA_VERSION-$PYTHIA_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION GSL/$GSL_VERSION-$GSL_REVISION Rivet/$RIVET_VERSION-$RIVET_REVISION
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv THEPEG_BASEDIR \$prefix
} else {
  setenv THEPEG_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
prepend-path PATH \$::env(THEPEG_ROOT)/bin
setenv ThePEG_INSTALL_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
EoF
