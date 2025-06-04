package: ThePEG
version: "%(tag_basename)s"
tag: "v2.3.0-alice1"
source: https://github.com/alisw/thepeg
requires:
  - Rivet
  - pythia
  - HepMC3
  - boost
  - GSL
build_requires:
  - "autotools:(slc6|slc7)"
  - GMP
prepend_path:
  LD_LIBRARY_PATH: "$THEPEG_ROOT/lib/ThePEG"
env:
  ThePEG_INSTALL_PATH: "$THEPEG_ROOT/lib/ThePEG"
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

export LDFLAGS="-Wl,--no-as-needed -L${MPFR_ROOT}/lib -L${GMP_ROOT}/lib -L${CGAL_ROOT}/lib"
export CXXFLAGS="-I${CGAL_ROOT}/include"
export LIBRARY_PATH="$LD_LIBRARY_PATH"

if [[ "$BOOST_ROOT" != '' ]]; then
  export LDFLAGS="$LDFLAGS -L$BOOST_ROOT/lib"
  export CXXFLAGS="$CXXFLAGS -I$BOOST_ROOT/include"
fi
if printf "int main(){}" | c++ $LDFLAGS -lboost_thread -lboost_system -xc++ - -o /dev/null; then
  export LDFLAGS="$LDFLAGS -lboost_thread -lboost_system"
else
  export LDFLAGS="$LDFLAGS -lboost_thread-mt -lboost_system-mt"
fi

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

# Override perl from AliEn-Runtime
mkdir -p fakeperl/bin
ln -nfs /usr/bin/perl fakeperl/bin/perl
export PATH="$PWD/fakeperl/bin:$PATH"

# special treatment for ThePEG version used for DIPSY
if [[ "$PKGVERSION" =~ "v2015-08-11" ]]; then
    sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/Config/interfaces.pl.in
    sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.am
    sed -i -e 's#@PYTHIA8_DIR@/xmldoc#@PYTHIA8_DIR@/share/Pythia8/xmldoc#' TheP8I/src/Makefile.in
fi

autoreconf -ivf
export LDFLAGS="-L$LHAPDF_ROOT/lib"
./configure                            \
  --disable-silent-rules               \
  --enable-shared                      \
  --enable-stdcxx11                    \
  --disable-static                     \
  --without-javagui                    \
  --prefix="$INSTALLROOT"              \
  ${GSL_ROOT:+--with-gsl="$GSL_ROOT"}  \
  --with-pythia8="$PYTHIA_ROOT"        \
  --with-hepmc="$HEPMC3_ROOT"          \
  --with-hepmcversion=3                \
  --with-rivet="$RIVET_ROOT"           \
  --with-lhapdf="$LHAPDF_ROOT"         \
  --with-fastjet="$FASTJET_ROOT"       \
  --enable-unitchecks 2>&1 | tee -a thepeg_configure.log
grep -q 'Cannot build TheP8I without a working Pythia8 installation.' thepeg_configure.log && false
make C_INCLUDE_PATH="${GSL_ROOT}/include" CPATH="${GSL_ROOT}/include" ${JOBS:+-j $JOBS}
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
module load BASE/1.0 pythia/$PYTHIA_VERSION-$PYTHIA_REVISION HepMC3/$HEPMC3_VERSION-$HEPMC3_REVISION Rivet/$RIVET_VERSION-$RIVET_REVISION ${GSL_REVISION:+GSL/$GSL_VERSION-$GSL_REVISION}
# Our environment
set THEPEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv THEPEG_ROOT \$THEPEG_ROOT
setenv ThePEG_INSTALL_PATH \$::env(THEPEG_ROOT)/lib/ThePEG
prepend-path PATH \$THEPEG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$THEPEG_ROOT/lib/ThePEG
EoF
