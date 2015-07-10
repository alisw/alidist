package: ThePEG
version: v20150318
source: https://github.com/alisw/thepeg
tag: "alice/v2015-03-18"
requires:
  - Rivet
  - GSL
  - FastJet
---
#!/bin/bash -e

Pythia8='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/pythia/v8186'
HepMC='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/HepMC/v2.06.09'
LhaPDF='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/lhapdf/v5.9.1'
Cgal='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/cgal/v4.4'
Boost='/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0'

export LD_LIBRARY_PATH="${LhaPDF}/lib:${Cgal}/lib:${Boost}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${LhaPDF}/lib:${Cgal}/lib:${Boost}/lib:${LIBRARY_PATH}"
export LHAPATH="${LhaPDF}/share/lhapdf/PDFsets"

cd "$SOURCEDIR"

find . \
  -name configure.ac -or \
  -name aclocal.m4 -or \
  -name configure -or \
  -name Makefile.am -or \
  -name Makefile.in \
  -exec touch '{}' \;
autoreconf -ivf
./configure \
  --disable-silent-rules \
  --enable-shared \
  --disable-static \
  --without-javagui \
  --prefix="$INSTALLROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-pythia8="$Pythia8" \
  --with-hepmc="$HepMC" \
  --with-rivet="$RIVET_ROOT" \
  --with-lhapdf="$LhaPDF" \
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
module load BASE/1.0 lhapdf/v5.9.1 pythia/v8186 HepMC/v2.06.09 FastJet/$FASTJET_VERSION-$FASTJET_REVISION GSL/$GSL_VERSION-$GSL_REVISION Rivet/$RIVET_VERSION-$RIVET_REVISION
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv THEPEG_ROOT \$prefix
} else {
  setenv THEPEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
prepend-path PATH \$::env(THEPEG_ROOT)/bin
setenv ThePEG_INSTALL_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
EoF
