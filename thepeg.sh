package: ThePEG
version: v20150318
source: https://github.com/alisw/thepeg
tag: "alice/v2015-03-18"
requires:
  - Rivet
  - pythia
  - HepMC
build_requires:
  - autotools
prepend_path:
  LD_LIBRARY_PATH: "$THEPEG_ROOT/lib/ThePEG"
  DYLD_LIBRARY_PATH: "$THEPEG_ROOT/lib/ThePEG"
env:
  ThePEG_INSTALL_PATH: "$THEPEG_ROOT/lib/ThePEG"
---
#!/bin/bash -e

export LD_LIBRARY_PATH="${LHAPDF5_ROOT}/lib:${CGAL_ROOT}/lib:${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${LHAPDF5_ROOT}/lib:${CGAL_ROOT}/lib:${BOOST_ROOT}/lib:${LIBRARY_PATH}"
export LHAPATH="${LHAPDF5_ROOT}/share/lhapdf"
export PERLLIB=/usr/share/perl5

rsync -a --delete $SOURCEDIR/ ./

sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/Config/interfaces.pl.in
sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.am
sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.in

autoreconf -ivf
export LDFLAGS="-L$LHAPDF5_ROOT/lib"
./configure \
  --disable-silent-rules \
  --enable-shared \
  --disable-static \
  --without-javagui \
  --prefix="$INSTALLROOT" \
  --with-gsl="$GSL_ROOT" \
  --with-pythia8="$PYTHIA_ROOT" \
  --with-hepmc="$HEPMC_ROOT" \
  --with-rivet="$RIVET_ROOT" \
  --with-lhapdf="$LHAPDF5_ROOT" \
  --with-fastjet="$FASTJET_ROOT" \
  --enable-unitchecks 2>&1 | tee -a thepeg_configure.log
grep -q 'Cannot build TheP8I without a working Pythia8 installation.' thepeg_configure.log && false
make ${JOBS:+-j$JOBS} C_INCLUDE_PATH="${GSL_ROOT}/include" CPATH="${GSL_ROOT}/include"
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
module load BASE/1.0 pythia/$PYTHIA_VERSION-$PYTHIA_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION Rivet/$RIVET_VERSION-$RIVET_REVISION
# Our environment
setenv THEPEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ThePEG_INSTALL_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
prepend-path PATH \$::env(THEPEG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
EoF
