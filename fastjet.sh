package: fastjet
version: "v3.1.3_1.017"
requires:
 - cgal
 - boost
 - HepMC
 - LHAPDF
---
#!/bin/bash -e

VerWithoutV=${PKGVERSION:1}
VerFJContrib="${VerWithoutV#*_}"
VerFJ="${VerWithoutV%%_*}"

UrlFJ="http://fastjet.fr/repo/fastjet-${VerFJ}.tar.gz"
UrlFJContrib="http://fastjet.hepforge.org/contrib/downloads/fjcontrib-${VerFJContrib}.tar.gz"

curl -Lo fastjet.tar.gz "$UrlFJ"
curl -Lo fjcontrib.tar.gz "$UrlFJContrib"

tar xzf fastjet.tar.gz
tar xzf fjcontrib.tar.gz

export LD_LIBRARY_PATH="${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${BOOST_ROOT}/lib:${LIBRARY_PATH}"

# Build FastJet
cd $BUILDDIR/fastjet-$VerFJ
export CXXFLAGS="-Wl,--no-as-needed -lgmp -L${BOOST_ROOT}/lib -lboost_thread -lboost_system -L${CGAL_ROOT}/lib -I${BOOST_ROOT}/include -I${CGAL_ROOT}/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"
export CFLAGS="${CXXFLAGS}"
export CPATH="${BOOST_ROOT}/include:${CGAL_ROOT}/include"
export C_INCLUDE_PATH="${BOOST_ROOT}/include:${CGAL_ROOT}/include"
./configure \
  --enable-shared \
  --enable-cgal \
  --with-cgal="${CGAL_ROOT}" \
  --prefix="$INSTALLROOT" \
  --enable-allcxxplugins
make -j$JOBS
make install -j$JOBS

# Build FastJet Contrib
cd $BUILDDIR/fjcontrib-$VerFJContrib
./configure \
  --fastjet-config=$INSTALLROOT/bin/fastjet-config \
  CXXFLAGS="$CXXFLAGS" \
  CFLAGS="$CFLAGS" \
  CPATH="$CPATH" \
  C_INCLUDE_PATH="$C_INCLUDE_PATH"
make -j$JOBS
make install
make fragile-shared -j$JOBS
make fragile-shared-install

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
module load BASE/1.0 cgal/v4.4
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv FASTJET \$prefix
} else {
  setenv FASTJET \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(FASTJET)/lib
prepend-path PATH \$::env(FASTJET)/bin
EoF
