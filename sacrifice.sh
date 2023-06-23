package: Sacrifice
version: "%(tag_basename)s"
tag: "v1.1.1-alice3"
source: https://github.com/alisw/Sacrifice.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - boost
  - lhapdf
  - HepMC
  - Python-modules
  - pythia
build_requires:
  - "autotools:(slc6|slc7)"
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
  ;;
  *)
    ARCH_LDFLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

autoreconf -ivf
./configure                                 \
  --with-HepMC="$HEPMC_ROOT"                \
  --with-LHAPDF="$LHAPDF_ROOT"              \
  --with-pythia="$PYTHIA_ROOT"              \
  --prefix="$INSTALLROOT"
make -j$JOBS
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
module load BASE/1.0 HepMC/$HEPMC_VERSION-$HEPMC_REVISION lhapdf/${LHAPDF_VERSION}-${LHAPDF_REVISION} ${BOOST_ROOT:+boost/$BOOST_VERSION-$BOOST_REVISION} ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} pythia/${PYTHIA_VERSION}-${PYTHIA_REVISION}
# Our environment
set SACRIFICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SACRIFICE_ROOT \$SACRIFICE_ROOT
prepend-path PYTHONPATH \$SACRIFICE_ROOT/lib/python2.7/site-packages
prepend-path PATH \$SACRIFICE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$SACRIFICE_ROOT/lib
EoF
