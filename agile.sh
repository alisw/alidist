package: AGILe
version: "%(tag_basename)s%(defaults_upper)s"
tag: "alice/v1.4.1"
source: https://github.com/alisw/AGILe.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - boost
  - lhapdf5
  - HepMC
  - Python
build_requires:
  - autotools
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

autoreconf -ifv
./configure                                 \
  ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"} \
  --with-hepmc="$HEPMC_ROOT"                \
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
module load BASE/1.0 HepMC/$HEPMC_VERSION-$HEPMC_REVISION lhapdf5/${LHAPDF5_VERSION}-${LHAPDF5_REVISION} ${BOOST_ROOT:+boost/$BOOST_VERSION-$BOOST_REVISION} ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}
# Our environment
setenv AGILE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$::env(AGILE_ROOT)/lib/python2.7/site-packages
prepend-path PATH \$::env(AGILE_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(AGILE_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(AGILE_ROOT)/lib")
EoF
