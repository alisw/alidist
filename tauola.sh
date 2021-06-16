package: TAUOLA
version: "%(tag_basename)s"
tag: "v1.1.5"
source: https://github.com/PMunkes/Tauolapp.git
requires:
  - HepMC
  - lhapdf
  - pythia
build_requires:
  - alibuild-recipe-tools
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
alibuild-generate-module --bin --lib --root-env --extra > "etc/modulefiles/$PKGNAME" <<\EoF
setenv TAUOLA_INSTALL_PATH $::env(TAUOLA_ROOT)/lib/TAUOLA
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
