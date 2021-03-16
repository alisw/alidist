package: TAUOLA
version: "%(tag_basename)s"
tag: "v1.1.5"
source: https://github.com/PMunkes/Tauolapp.git
requires:
  - HepMC
  - lhapdf
  - pythia
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

# fix this error: required file './README' not found
cp README.md README

autoreconf -ifv
./configure --prefix $INSTALLROOT \
	    --with-hepmc="$HEPMC_ROOT" \
	    --with-pythia8="$PYTHIA_ROOT" \
	    --with-lhapdf="$LHAPDF_ROOT"
make -j$JOBS
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME

cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set TAUOLA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv TAUOLA_ROOT \$TAUOLA_ROOT
setenv TAUOLA_INSTALL_PATH \$::env(TAUOLA_ROOT)/lib/TAUOLA
prepend-path PATH \$TAUOLA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$TAUOLA_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
